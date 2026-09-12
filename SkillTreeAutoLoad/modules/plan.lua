local NS = SkillTreeAutoLoad

local Plan = {}
NS.Plan = Plan

local parentsOf, childrenOf, maxRankOf, costsOf, isStartNode

-- `x or {}` dans une boucle alloue une table par tour des que x est nil. Une seule
-- table vide, jamais ecrite, dit la meme chose sans rien couter.
local EMPTY = {}

-- Le graphe de l'arbre ne bouge pas d'une session a l'autre : on le construit une
-- seule fois, a la premiere demande, et on le garde.
local function BuildGraph()
    if parentsOf then return true end

    local tree = TalentDatabase and TalentDatabase[0]
    if not (tree and tree.nodes and tree.links) then return false end

    parentsOf, childrenOf, maxRankOf, costsOf, isStartNode = {}, {}, {}, {}, {}

    for _, node in ipairs(tree.nodes) do
        -- Meme definition que ProjectEbonhold : le rang maximum est le nombre de
        -- sorts du noeud, pas la longueur de sa table de couts.
        maxRankOf[node.id] = #(node.spells or {})
        costsOf[node.id] = node.soulPointsCosts or {}
        if node.isStart then isStartNode[node.id] = true end
    end

    -- Un lien { a, b } se lit « a est parent de b ». On garde les deux sens : les
    -- parents disent si un noeud est ouvert, les enfants disent qui vient de
    -- s'ouvrir quand un noeud atteint enfin son rang maximum.
    for _, link in ipairs(tree.links) do
        local parentId, childId = link[1], link[2]

        local parents = parentsOf[childId]
        if not parents then
            parents = {}
            parentsOf[childId] = parents
        end
        parents[#parents + 1] = parentId

        local kids = childrenOf[parentId]
        if not kids then
            kids = {}
            childrenOf[parentId] = kids
        end
        kids[#kids + 1] = childId
    end

    return true
end

local function RankCost(nodeId, fromRank, toRank)
    local costs = costsOf[nodeId]
    if not costs then return 0 end

    local total = 0
    for rank = fromRank + 1, toRank do
        total = total + (costs[rank] or 0)
    end
    return total
end

-- Ce que la save ajouterait a l'arbre tel qu'il est. Ne depend pas du graphe : c'est
-- une simple difference, et l'overlay s'en sert pour dessiner la save en entier.
function Plan.ComputeMissing(targets, snapshot)
    local missing, count = {}, 0
    snapshot = snapshot or EMPTY

    for nodeId, targetRank in pairs(targets or EMPTY) do
        if (snapshot[nodeId] or 0) < targetRank then
            missing[nodeId] = targetRank
            count = count + 1
        end
    end

    return missing, count
end

-- Avancement d'une save, pondere par les cendres et non par le nombre de noeuds :
-- les premiers coutent 50, les derniers 52 500. Compter les noeuds annoncerait une
-- save presque finie alors qu'il reste l'essentiel de la facture a payer.
function Plan.ComputeProgress(targets, snapshot)
    if not BuildGraph() then return nil end

    snapshot = snapshot or EMPTY
    local ownedCost, totalCost, ownedNodes, totalNodes = 0, 0, 0, 0

    -- Les couts du noeud sont parcourus une fois pour les deux totaux, au lieu de
    -- deux appels a RankCost qui relisaient la meme table. Sur une save complete
    -- cette boucle tourne 643 fois a chaque redessin de la liste : ce qu'on y pose
    -- s'y paie autant de fois.
    for nodeId, targetRank in pairs(targets or EMPTY) do
        if maxRankOf[nodeId] then
            local costs = costsOf[nodeId]
            local currentRank = snapshot[nodeId] or 0
            if currentRank > targetRank then currentRank = targetRank end

            for rank = 1, targetRank do
                local cost = costs[rank] or 0
                totalCost = totalCost + cost
                if rank <= currentRank then ownedCost = ownedCost + cost end
            end

            totalNodes = totalNodes + 1
            if currentRank >= targetRank then ownedNodes = ownedNodes + 1 end
        end
    end

    return ownedCost, totalCost, ownedNodes, totalNodes
end

-- Tas binaire sur le couple (cout du prochain rang, id du noeud) : exactement
-- l'ordre que departageait la comparaison du choix glouton, le moins cher d'abord
-- et le plus petit id a cout egal.
local function HeapPush(costs, ids, size, cost, id)
    size = size + 1

    local i = size
    while i > 1 do
        local up = math.floor(i / 2)
        local upCost, upId = costs[up], ids[up]
        if upCost < cost or (upCost == cost and upId < id) then break end
        costs[i], ids[i] = upCost, upId
        i = up
    end

    costs[i], ids[i] = cost, id
    return size
end

local function HeapPop(costs, ids, size)
    local topCost, topId = costs[1], ids[1]
    local holdCost, holdId = costs[size], ids[size]

    costs[size], ids[size] = nil, nil
    size = size - 1

    if size > 0 then
        local i = 1
        while true do
            local down = i * 2
            if down > size then break end

            local right = down + 1
            if right <= size then
                local leftCost, leftId = costs[down], ids[down]
                local rightCost, rightId = costs[right], ids[right]
                if rightCost < leftCost or (rightCost == leftCost and rightId < leftId) then
                    down = right
                end
            end

            local downCost, downId = costs[down], ids[down]
            if holdCost < downCost or (holdCost == downCost and holdId < downId) then break end
            costs[i], ids[i] = downCost, downId
            i = down
        end
        costs[i], ids[i] = holdCost, holdId
    end

    return topCost, topId, size
end

-- Regle recopiee de `hasPrerequisites` : un noeud de depart est toujours ouvert, et
-- tout autre noeud exige TOUS ses parents au rang maximum. Un noeud sans parent qui
-- n'est pas un depart reste donc ferme, exactement comme cote serveur.
--
-- On ne la rejoue pas a chaque tour : on compte une fois les parents qui manquent, et
-- un parent que le plan ne menera pas jusqu'a son maximum ferme le noeud pour de bon.
-- Ceux qui attendent encore sont ranges dans `waiting`, ou seul l'achat d'un parent
-- viendra les rechercher.
local function ClassifyNode(nodeId, ranks, goals, waiting)
    if isStartNode[nodeId] then return true end

    local parents = parentsOf[nodeId]
    if not parents then return false end

    local unmet = 0
    for i = 1, #parents do
        local parentId = parents[i]
        local parentMax = maxRankOf[parentId] or 0

        if parentMax == 0 then return false end

        if (ranks[parentId] or 0) < parentMax then
            if goals[parentId] ~= parentMax then return false end
            unmet = unmet + 1
        end
    end

    if unmet == 0 then return true end

    waiting[nodeId] = unmet
    return false
end

-- Achat glouton, rang par rang : a chaque tour on prend le rang ouvert le moins cher,
-- puis on recommence avec ce qui reste. C'est la suite de clics la moins chere, donc
-- la plus previsible — et le joueur la relit sur l'arbre avant de valider, l'overlay
-- la lui montre en vert. On rend aussi le prix du premier rang hors budget, qui est
-- le seul chiffre utile quand plus rien n'est payable.
--
-- Les noeuds ouverts sont tenus dans un tas plutot que rebalayes a chaque tour : un
-- achat n'ouvre que les enfants du noeud qu'il vient de terminer, et le sommet du tas
-- est deja le rang le moins cher. Le temps ne depend donc plus du carre du nombre de
-- noeuds de la save — ce qui se voyait a l'ecran, la liste etant redessinee des que
-- la reserve bouge, c'est-a-dire a chaque clic du joueur dans l'arbre.
function Plan.ComputeProgressive(targets, snapshot, budget)
    if not BuildGraph() then return nil end

    local ranks = {}
    for nodeId, rank in pairs(snapshot or EMPTY) do ranks[nodeId] = rank end

    -- La cible est plafonnee au rang maximum du noeud. Une save abimee qui
    -- demanderait un rang absurde ferait tourner la boucle autant de fois qu'elle
    -- annonce : le client se figerait, sans rien afficher.
    local goals = {}

    for nodeId, targetRank in pairs(targets or EMPTY) do
        local maxRank = maxRankOf[nodeId]
        if maxRank then
            local goal = (targetRank > maxRank) and maxRank or targetRank
            if (ranks[nodeId] or 0) < goal then goals[nodeId] = goal end
        end
    end

    -- Deux passes et non une : le classement d'un noeud lit les objectifs de ses
    -- parents, qui ne sont tous connus qu'a la fin de la premiere.
    local heapCosts, heapIds, heapSize = {}, {}, 0
    local waiting = {}

    for nodeId in pairs(goals) do
        if ClassifyNode(nodeId, ranks, goals, waiting) then
            local rank = ranks[nodeId] or 0
            heapSize = HeapPush(heapCosts, heapIds, heapSize,
                RankCost(nodeId, rank, rank + 1), nodeId)
        end
    end

    local chosen, chosenCount, spent = {}, 0, 0
    local remaining = budget or 0
    local blockedCost

    -- Chaque tour retire un rang du tas, et n'en remet au plus qu'un par noeud
    -- ouvert : la boucle ne peut pas survivre a ses donnees.
    while heapSize > 0 do
        local cost, nodeId
        cost, nodeId, heapSize = HeapPop(heapCosts, heapIds, heapSize)

        -- Le sommet est le moins cher de tout ce qui est ouvert : s'il ne passe pas,
        -- rien ne passe, et c'est deja le chiffre a annoncer au joueur.
        if cost > remaining then
            blockedCost = cost
            break
        end

        local newRank = (ranks[nodeId] or 0) + 1
        if not chosen[nodeId] then chosenCount = chosenCount + 1 end
        ranks[nodeId] = newRank
        chosen[nodeId] = newRank
        remaining = remaining - cost
        spent = spent + cost

        if newRank < goals[nodeId] then
            heapSize = HeapPush(heapCosts, heapIds, heapSize,
                RankCost(nodeId, newRank, newRank + 1), nodeId)
        end

        if newRank >= (maxRankOf[nodeId] or 0) then
            local kids = childrenOf[nodeId]
            for i = 1, (kids and #kids or 0) do
                local childId = kids[i]
                local unmet = waiting[childId]
                if unmet then
                    unmet = unmet - 1
                    if unmet > 0 then
                        waiting[childId] = unmet
                    else
                        waiting[childId] = nil
                        local rank = ranks[childId] or 0
                        heapSize = HeapPush(heapCosts, heapIds, heapSize,
                            RankCost(childId, rank, rank + 1), childId)
                    end
                end
            end
        end
    end

    return chosen, spent, chosenCount, blockedCost
end

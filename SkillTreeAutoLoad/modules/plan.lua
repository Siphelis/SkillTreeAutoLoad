local NS = SkillTreeAutoLoad

local Plan = {}
NS.Plan = Plan

local parentsOf, maxRankOf, costsOf, isStartNode

-- Le graphe de l'arbre ne bouge pas d'une session a l'autre : on le construit une
-- seule fois, a la premiere demande, et on le garde.
local function BuildGraph()
    if parentsOf then return true end

    local tree = TalentDatabase and TalentDatabase[0]
    if not (tree and tree.nodes and tree.links) then return false end

    parentsOf, maxRankOf, costsOf, isStartNode = {}, {}, {}, {}

    for _, node in ipairs(tree.nodes) do
        -- Meme definition que ProjectEbonhold : le rang maximum est le nombre de
        -- sorts du noeud, pas la longueur de sa table de couts.
        maxRankOf[node.id] = #(node.spells or {})
        costsOf[node.id] = node.soulPointsCosts or {}
        if node.isStart then isStartNode[node.id] = true end
    end

    -- Un lien { a, b } se lit « a est parent de b ».
    for _, link in ipairs(tree.links) do
        local parentId, childId = link[1], link[2]
        local list = parentsOf[childId]
        if not list then
            list = {}
            parentsOf[childId] = list
        end
        list[#list + 1] = parentId
    end

    return true
end

-- Regle recopiee de `hasPrerequisites` : un noeud de depart est toujours ouvert, et
-- tout autre noeud exige TOUS ses parents au rang maximum. Un noeud sans parent qui
-- n'est pas un depart reste donc ferme, exactement comme cote serveur.
local function ParentsSatisfied(nodeId, ranks)
    if isStartNode[nodeId] then return true end

    local parents = parentsOf[nodeId]
    if not parents then return false end

    for i = 1, #parents do
        local parentId = parents[i]
        local parentMax = maxRankOf[parentId] or 0
        if parentMax == 0 or (ranks[parentId] or 0) < parentMax then return false end
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

    for nodeId, targetRank in pairs(targets or {}) do
        if ((snapshot or {})[nodeId] or 0) < targetRank then
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

    local ownedCost, totalCost, ownedNodes, totalNodes = 0, 0, 0, 0

    for nodeId, targetRank in pairs(targets or {}) do
        if maxRankOf[nodeId] then
            local currentRank = math.min((snapshot or {})[nodeId] or 0, targetRank)

            totalCost = totalCost + RankCost(nodeId, 0, targetRank)
            ownedCost = ownedCost + RankCost(nodeId, 0, currentRank)

            totalNodes = totalNodes + 1
            if currentRank >= targetRank then ownedNodes = ownedNodes + 1 end
        end
    end

    return ownedCost, totalCost, ownedNodes, totalNodes
end

-- Achat glouton, rang par rang : a chaque tour on prend le rang ouvert le moins cher,
-- puis on recommence avec ce qui reste. C'est la suite de clics la moins chere, donc
-- la plus previsible — et le joueur la relit sur l'arbre avant de valider, l'overlay
-- la lui montre en vert. On rend aussi le prix du premier rang hors budget, qui est
-- le seul chiffre utile quand plus rien n'est payable.
function Plan.ComputeProgressive(targets, snapshot, budget)
    if not BuildGraph() then return nil end

    local ranks = {}
    for nodeId, rank in pairs(snapshot or {}) do ranks[nodeId] = rank end

    -- La cible est plafonnee au rang maximum du noeud. Une save abimee qui
    -- demanderait un rang absurde ferait tourner la boucle autant de fois qu'elle
    -- annonce : le client se figerait, sans rien afficher.
    local goals = {}
    local pending, steps = {}, 0

    for nodeId, targetRank in pairs(targets or {}) do
        local maxRank = maxRankOf[nodeId]
        if maxRank then
            local goal = (targetRank > maxRank) and maxRank or targetRank
            if (ranks[nodeId] or 0) < goal then
                goals[nodeId] = goal
                pending[#pending + 1] = nodeId
                steps = steps + goal
            end
        end
    end

    local chosen, chosenCount, spent = {}, 0, 0
    local remaining = budget or 0
    local blockedCost

    -- Chaque tour achete exactement un rang : le nombre de rangs restants borne
    -- le nombre de tours, et la boucle ne peut plus survivre a ses donnees.
    for _ = 1, steps do
        local bestId, bestCost, cheapest
        local i = 1

        while i <= #pending do
            local nodeId = pending[i]
            local currentRank = ranks[nodeId] or 0

            if currentRank >= goals[nodeId] then
                -- Noeud termine : on le sort de la liste sans avancer l'index.
                pending[i] = pending[#pending]
                pending[#pending] = nil
            else
                if ParentsSatisfied(nodeId, ranks) then
                    local step = RankCost(nodeId, currentRank, currentRank + 1)

                    if not cheapest or step < cheapest then cheapest = step end

                    if step <= remaining
                        and (not bestCost or step < bestCost
                            or (step == bestCost and nodeId < bestId)) then
                        bestId, bestCost = nodeId, step
                    end
                end
                i = i + 1
            end
        end

        if not bestId then
            blockedCost = cheapest
            break
        end

        local newRank = (ranks[bestId] or 0) + 1
        if not chosen[bestId] then chosenCount = chosenCount + 1 end
        ranks[bestId] = newRank
        chosen[bestId] = newRank
        remaining = remaining - bestCost
        spent = spent + bestCost
    end

    return chosen, spent, chosenCount, blockedCost
end

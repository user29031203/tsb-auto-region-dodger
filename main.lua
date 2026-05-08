local TARGET_PLACE_ID = 12360882630 -- Uses the current game's PlaceId

local scriptTemplate = [[
    local template = %q
    local placeIdToJoin = %d
    
    -- Re-queue for the next teleport
    queue_on_teleport(string.format(template, template, placeIdToJoin))
    
    task.spawn(function()
        task.wait(5) -- Let the connection and leaderstats stabilize/load
        
        local Players = game:GetService("Players")
        local TeleportService = game:GetService("TeleportService")
        local PathfindingService = game:GetService("PathfindingService")
        local player = Players.LocalPlayer
        
        -- === PATHFINDING FUNCTIONS ===
        local function formatVec(vec)
            return "(" .. math.round(vec.X*100)/100 .. ", " .. math.round(vec.Y*100)/100 .. ", " .. math.round(vec.Z*100)/100 .. ")"
        end

        local function smartWalkTo(targetPosition)
            local char = player.Character or player.CharacterAdded:Wait()
            local hum = char:WaitForChild("Humanoid")
            local root = char:WaitForChild("HumanoidRootPart")

            print("\n------------------------------------------------")
            print("CALCULATING PATH TO: " .. formatVec(targetPosition))

            local path = PathfindingService:CreatePath({
                AgentRadius = 2,
                AgentCanJump = true
            })

            path:ComputeAsync(root.Position, targetPosition)

            if path.Status == Enum.PathStatus.Success then
                local waypoints = path:GetWaypoints()

                for i, waypoint in ipairs(waypoints) do
                    local targetVec = waypoint.Position
                    
                    if waypoint.Action == Enum.PathWaypointAction.Jump then
                        hum.Jump = true
                    end
                    
                    hum:MoveTo(targetVec)
                    
                    local reached = false
                    local timeout = 0
                    
                    repeat 
                        task.wait()
                        timeout = timeout + 1
                        
                        local currentPos = root.Position
                        local distXZ = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(targetVec.X, 0, targetVec.Z)).Magnitude
                        
                        if distXZ < 1.5 then reached = true end
                    until reached or timeout > 200
                    
                    local actualPos = root.Position
                    local diff = actualPos - targetVec
                    
                    print("\n[WAYPOINT " .. tostring(i) .. "]")
                    print("Target (Pathfinder): " .. formatVec(targetVec))
                    print("Actual (RootPart)  : " .. formatVec(actualPos))
                    print("Difference         : X:" .. math.round(diff.X*100)/100 .. " | Y:" .. math.round(diff.Y*100)/100 .. " | Z:" .. math.round(diff.Z*100)/100)
                end
                print("\nPATH COMPLETE")
            else
                warn("PATHFINDING FAILED!")
            end
        end
        -- ==============================
        
        if player then
            local pingMs = math.round(player:GetNetworkPing() * 1000)
            
            local hasTargetColumns = false
            local leaderstats = player:FindFirstChild("leaderstats")
            
            if leaderstats then
                local hasStreak = leaderstats:FindFirstChild("Streak") ~= nil
                local hasSolo = leaderstats:FindFirstChild("Solo Rank") ~= nil
                local hasDuo = leaderstats:FindFirstChild("Duo Rank") ~= nil
                
                if hasStreak and hasSolo and hasDuo then
                    hasTargetColumns = true
                end
            end
            
            print("Hello, World! Current ping is: " .. pingMs .. "ms")
            
            local shouldTeleport = false
            
            if hasTargetColumns then
                print("Found Streak, Solo Rank, and Duo Rank! Staying in this server.")
            elseif pingMs >= 100 then
                print("Missing required columns and ping is high (" .. pingMs .. "ms). Teleporting...")
                shouldTeleport = true
            else
                print("Ping is good (" .. pingMs .. "ms). Staying in this server.")
            end
        
            if shouldTeleport then
                print("starting tp process rn")
                TeleportService:Teleport(placeIdToJoin, player)
            elseif hasTargetColumns then
                print("No need to teleport. Walking to Hoster Position...")
                local hosterPos = Vector3.new(196, 437, -1080)
                smartWalkTo(hosterPos)
            else
                print("No need to teleport nor do something.")
            end
        end
    end)
]]

local initialCode = string.format(scriptTemplate, scriptTemplate, TARGET_PLACE_ID)
queue_on_teleport(initialCode)

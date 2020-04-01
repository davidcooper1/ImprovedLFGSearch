_G["IMPROVEDLFGSEARCH_ENHANCEDSEARCH_LABEL"] = "Enhanced Search";

local OldLFGListSearchPanel_DoSearch = LFGListSearchPanel_DoSearch;

local playerRoleKey = nil;

local roleRemainingKeyLookup = {
	["TANK"] = "TANK_REMAINING",
	["HEALER"] = "HEALER_REMAINING",
	["DAMAGER"] = "DAMAGER_REMAINING",
};

local function SetInputStates(state)
    if (state) then
        ImprovedLFGSearchPanel_Options.EnhancedSearch.CheckButton:Enable();
        ImprovedLFGSearchPanel_Options.LiveSorting.CheckButton:Enable();
    else
        ImprovedLFGSearchPanel_Options.EnhancedSearch.CheckButton:Disable();
        ImprovedLFGSearchPanel_Options.LiveSorting.CheckButton:Disable();
    end
end

local function GetPlayerRoleKey()
    return roleRemainingKeyLookup[GetSpecializationRole(GetSpecialization())];
end

local function HasRemainingSlotsForLocalPlayerRole(lfgSearchResultID)
	local roles = C_LFGList.GetSearchResultMemberCounts(lfgSearchResultID);
	return roles[playerRoleKey] > 0;
end

function NewLFGListUtil_SortSearchResultsCB(searchResultID1, searchResultID2)
	local searchResultInfo1 = C_LFGList.GetSearchResultInfo(searchResultID1);
	local searchResultInfo2 = C_LFGList.GetSearchResultInfo(searchResultID2);

	local hasRemainingRole1 = HasRemainingSlotsForLocalPlayerRole(searchResultID1);
    local hasRemainingRole2 = HasRemainingSlotsForLocalPlayerRole(searchResultID2);
    
    if (searchResultInfo1.isDelisted and not searchResultInfo2.isDelisted) then
        return false;
    elseif (not searchResultInfo1.isDelisted and searchResultInfo2.isDelisted) then
        return true;
    end

    -- Groups with your current role available are preferred
    if (hasRemainingRole1 ~= hasRemainingRole2) then
        return hasRemainingRole1;
    end

    --If one has more friends, do that one first
    if ( searchResultInfo1.numBNetFriends ~= searchResultInfo2.numBNetFriends ) then
        return searchResultInfo1.numBNetFriends > searchResultInfo2.numBNetFriends;
    end

    if ( searchResultInfo1.numCharFriends ~= searchResultInfo2.numCharFriends ) then
        return searchResultInfo1.numCharFriends > searchResultInfo2.numCharFriends;
    end

    if ( searchResultInfo1.numGuildMates ~= searchResultInfo2.numGuildMates ) then
        return searchResultInfo1.numGuildMates > searchResultInfo2.numGuildMates;
    end

	--If we aren't sorting by anything else, just go by ID
	return searchResultID1 < searchResultID2;
end

function LFGListUtil_SortSearchResults(results)
    if (not playerRoleKey) then
        playerRoleKey = GetPlayerRoleKey();
    end

    if (ImprovedLFGSearch_UseEnhancedSearch) then
        table.sort(results, NewLFGListUtil_SortSearchResultsCB);
    else
        table.sort(results, LFGListUtil_SortSearchResultsCB);
    end
end

function LFGListSearchPanel_DoSearch(self) 
    SetInputStates(false);
    OldLFGListSearchPanel_DoSearch(self);
end

ImprovedLFGSearchPanel_Options:RegisterEvent("ADDON_LOADED");
ImprovedLFGSearchPanel_Options:RegisterEvent("PLAYER_LOGIN");
ImprovedLFGSearchPanel_Options:RegisterEvent("PLAYER_LOGOUT");
ImprovedLFGSearchPanel_Options:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");

function ImprovedLFGSearchPanel_Options:OnEvent(event, arg1)
    if (event == "ADDON_LOADED" and arg1 == "ImprovedLFGSearch") then
        if (ImprovedLFGSearch_UseEnhancedSearch == nil) then
            ImprovedLFGSearch_UseEnhancedSearch = true;
        end
        
        if (ImprovedLFGSearch_UseLiveSorting == nil) then
            ImprovedLFGSearch_UseLiveSorting = true;
        end
    elseif (event == "PLAYER_LOGIN") then
        playerRoleKey = GetPlayerRoleKey();
    elseif (event == "PLAYER_LOGOUT") then
        ImprovedLFGSearch_UseEnhancedSearch = ImprovedLFGSearchPanel_Options.EnhancedSearch.CheckButton:GetChecked();
        ImprovedLFGSearch_UseLiveSorting = ImprovedLFGSearchPanel_Options.LiveSorting.CheckButton:GetChecked();
    elseif (event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 == "player") then
        playerRoleKey = GetPlayerRoleKey();
        local results = LFGListFrame.SearchPanel.results;
        if (results ~= nil and #results > 0 and LFGListFrame.SearchPanel:IsShown() and ImprovedLFGSearch_UseLiveSorting) then
            UpdateSorting();
        end
    end
end

local function UpdateSorting() 
    LFGListSearchPanel_UpdateResultList(LFGListFrame.SearchPanel);
    LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
end

function ImprovedLFGSearchPanel_Options.EnhancedSearch:OnClick(self)
    ImprovedLFGSearch_UseEnhancedSearch = self:GetChecked();
    UpdateSorting();
end

function ImprovedLFGSearchPanel_Options.LiveSorting:OnClick(self)
    ImprovedLFGSearch_UseLiveSorting = self:GetChecked();
    if (self:GetChecked()) then
        UpdateSorting();
    end
end

ImprovedLFGSearchPanel_Options:SetScript("OnEvent", ImprovedLFGSearchPanel_Options.OnEvent)

-- LFGListFrame.SearchPanel Event Pre-Hooks
LFGListFrame.SearchPanel:SetScript("OnHide", function(...)
    ImprovedLFGSearchPanel_Options:Hide();
end);

local OldLFGListSearchPanel_OnShow = LFGListFrame.SearchPanel:GetScript("OnShow");
LFGListFrame.SearchPanel:SetScript("OnShow", function(...)
    ImprovedLFGSearchPanel_Options:Show();
    if (#LFGListFrame.SearchPanel.results and ImprovedLFGSearch_UseLiveSorting) then
        UpdateSorting(); 
    end
    OldLFGListSearchPanel_OnShow(...);
end);

local OldLFGListSearchPanel_OnEvent = LFGListFrame.SearchPanel:GetScript("OnEvent");
LFGListFrame.SearchPanel:SetScript("OnEvent", function(self, event, ...) 
    if (event == "LFG_LIST_SEARCH_RESULTS_RECEIVED") then
        SetInputStates(true);
    elseif (event == "LFG_LIST_SEARCH_RESULT_UPDATED" and ImprovedLFGSearch_UseLiveSorting and ImprovedLFGSearchPanel_Options:IsShown()) then
        UpdateSorting();
    elseif (event == "LFG_LIST_SEARCH_FAILED") then
        SetInputStates(true);
    end
    -- Pass through to the old event handler.
    OldLFGListSearchPanel_OnEvent(self, event, ...);
end);
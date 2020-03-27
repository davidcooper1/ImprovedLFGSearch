_G["IMPROVEDLFGSEARCH_ENHANCEDSEARCH_LABEL"] = "Enhanced Search";

local OldLFGListSearchPanel_DoSearch = LFGListSearchPanel_DoSearch;

local roleRemainingKeyLookup = {
	["TANK"] = "TANK_REMAINING",
	["HEALER"] = "HEALER_REMAINING",
	["DAMAGER"] = "DAMAGER_REMAINING",
};

local function HasRemainingSlotsForLocalPlayerRole(lfgSearchResultID)
	local roles = C_LFGList.GetSearchResultMemberCounts(lfgSearchResultID);
	local playerRole = GetSpecializationRole(GetSpecialization());
	return roles[roleRemainingKeyLookup[playerRole]] > 0;
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
    if (ImprovedLFGSearch_UseEnhancedSearch) then
        table.sort(results, NewLFGListUtil_SortSearchResultsCB);
    else
        table.sort(results, LFGListUtil_SortSearchResultsCB);
    end
end

function LFGListSearchPanel_DoSearch(self) 
    ImprovedLFGSearchPanel_Options.EnhancedSearch.CheckButton:Disable();
    ImprovedLFGSearchPanel_Options.LiveSorting.CheckButton:Disable();
    OldLFGListSearchPanel_DoSearch(self);
end

ImprovedLFGSearchPanel_Options:RegisterEvent("ADDON_LOADED");
ImprovedLFGSearchPanel_Options:RegisterEvent("PLAYER_LOGOUT");

function ImprovedLFGSearchPanel_Options:OnEvent(event, arg1)
    if (event == "ADDON_LOADED" and arg1 == "ImprovedLFGSearch") then
        if (ImprovedLFGSearch_UseEnhancedSearch == nil) then
            ImprovedLFGSearch_UseEnhancedSearch = true;
        end
        
        if (ImprovedLFGSearch_UseLiveSorting == nil) then
            ImprovedLFGSearch_UseLiveSorting = true;
        end
    elseif (event == "PLAYER_LOGOUT") then
        ImprovedLFGSearch_UseEnhancedSearch = ImprovedLFGSearchPanel_Options.EnhancedSearch.CheckButton:GetChecked();
        ImprovedLFGSearch_UseLiveSorting = ImprovedLFGSearchPanel_Options.LiveSorting.CheckButton:GetChecked();
    end
end

-- Check Boxes in Search Options Frame Click Pre-Hooks
local OldEnhancedSearchClickEvent = ImprovedLFGSearchPanel_Options.EnhancedSearch.CheckButton:GetScript("OnClick");
ImprovedLFGSearchPanel_Options.EnhancedSearch.CheckButton:SetScript("OnClick", function(self) 
    LFGListSearchPanel_UpdateResultList(LFGListFrame.SearchPanel);
    LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
    ImprovedLFGSearch_UseEnhancedSearch = self:GetChecked();
    OldEnhancedSearchClickEvent(self);
end);

local OldLiveSortingClickEvent = ImprovedLFGSearchPanel_Options.LiveSorting.CheckButton:GetScript("OnClick");
ImprovedLFGSearchPanel_Options.LiveSorting.CheckButton:SetScript("OnClick", function(self) 
    ImprovedLFGSearch_UseLiveSorting = self:GetChecked();
    if (self:GetChecked()) then
        LFGListSearchPanel_UpdateResultList(LFGListFrame.SearchPanel);
        LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
    end
    OldEnhancedSearchClickEvent(self);
end);

ImprovedLFGSearchPanel_Options:SetScript("OnEvent", ImprovedLFGSearchPanel_Options.OnEvent)



-- LFGListFrame.SearchPanel Event Pre-Hooks
LFGListFrame.SearchPanel:SetScript("OnHide", function(...)
    ImprovedLFGSearchPanel_Options:Hide();
end);

local OldLFGListSearchPanel_OnShow = LFGListFrame.SearchPanel:GetScript("OnShow");
LFGListFrame.SearchPanel:SetScript("OnShow", function(...)
    ImprovedLFGSearchPanel_Options:Show();
    OldLFGListSearchPanel_OnShow(...);
end);

local OldLFGListSearchPanel_OnEvent = LFGListFrame.SearchPanel:GetScript("OnEvent");
LFGListFrame.SearchPanel:SetScript("OnEvent", function(self, event, ...) 
    if (event == "LFG_LIST_SEARCH_RESULTS_RECEIVED") then
        ImprovedLFGSearchPanel_Options.EnhancedSearch.CheckButton:Enable();
        ImprovedLFGSearchPanel_Options.LiveSorting.CheckButton:Enable();
    elseif (event == "LFG_LIST_SEARCH_RESULT_UPDATED" and ImprovedLFGSearch_UseLiveSorting) then
        LFGListSearchPanel_UpdateResultList(self);
        LFGListSearchPanel_UpdateResults(self);
    end
    -- Pass through to the old event handler.
    OldLFGListSearchPanel_OnEvent(self, event, ...);
end);
OldLFGListSearchPanel_OnEvent = LFGListFrame.SearchPanel:GetScript("OnEvent");

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

function LFGListUtil_SortSearchResultsCB(searchResultID1, searchResultID2)
	local searchResultInfo1 = C_LFGList.GetSearchResultInfo(searchResultID1);
	local searchResultInfo2 = C_LFGList.GetSearchResultInfo(searchResultID2);

	local hasRemainingRole1 = HasRemainingSlotsForLocalPlayerRole(searchResultID1);
    local hasRemainingRole2 = HasRemainingSlotsForLocalPlayerRole(searchResultID2);
    
    if (searchResultInfo1.isDelisted == true and searchResultInfo2.isDelisted == false) then
        return false;
    elseif (searchResultInfo1.isDelisted == false and searchResultInfo2.isDelisted == true) then
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

function NewLFGListSearchPanel_OnEvent(self, event, ...) 
    if (event == "LFG_LIST_SEARCH_RESULT_UPDATED") then
        LFGListSearchPanel_UpdateResultList(self);
        LFGListSearchPanel_UpdateResults(self);
    end
    -- Pass through to the old event handler.
    OldLFGListSearchPanel_OnEvent(self, event, ...);
end

LFGListFrame.SearchPanel:SetScript("OnEvent", NewLFGListSearchPanel_OnEvent);
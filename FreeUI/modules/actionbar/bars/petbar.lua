local F, C, L = unpack(select(2, ...))
local ACTIONBAR = F.ACTIONBAR


local margin, padding = 3, 3

local function SetFrameSize(frame, size, num)
	size = size or frame.buttonSize
	num = num or frame.numButtons

	frame:SetWidth(num*size + (num-1)*margin + 2*padding)
	frame:SetHeight(size + 2*padding)
	if not frame.mover then
		frame.mover = F.Mover(frame, L.GUI.MOVER.PET_BAR, 'PetBar', frame.Pos)
	else
		frame.mover:SetSize(frame:GetSize())
	end

	if not frame.SetFrameSize then
		frame.buttonSize = size
		frame.numButtons = num
		frame.SetFrameSize = SetFrameSize
	end
end

function ACTIONBAR:CreatePetbar()
	local num = _G.NUM_PET_ACTION_SLOTS
	local size = C.DB.actionbar.button_size_small
	local buttonList = {}

	local frame = CreateFrame('Frame', 'FreeUI_ActionBarPet', UIParent, 'SecureHandlerStateTemplate')
	local anchor = _G.FreeUI_ActionBar2
	frame.Pos = {'BOTTOM', anchor, 'TOP', 0, margin}

	_G.PetActionBarFrame:SetParent(frame)
	_G.PetActionBarFrame:EnableMouse(false)
	_G.SlidingActionBarTexture0:SetTexture(nil)
	_G.SlidingActionBarTexture1:SetTexture(nil)

	for i = 1, num do
		local button = _G['PetActionButton'..i]
		tinsert(buttonList, button)
		tinsert(ACTIONBAR.buttons, button)
		button:ClearAllPoints()
		if i == 1 then
			button:SetPoint('LEFT', frame, padding, 0)
		else
			local previous = _G['PetActionButton'..i-1]
			button:SetPoint('LEFT', previous, 'RIGHT', margin, 0)
		end
	end

	frame.buttonList = buttonList
	SetFrameSize(frame, size, num)

	frame.frameVisibility = '[petbattle][overridebar][vehicleui][possessbar,@vehicle,exists][shapeshift] hide; [pet] show; hide'
	RegisterStateDriver(frame, 'visibility', frame.frameVisibility)

	if C.DB.actionbar.pet_bar_fade then
		frame.fader = {
			enable = C.DB.actionbar.pet_bar_fade,
			fadeInAlpha = C.DB.actionbar.pet_bar_fade_in_alpha,
			fadeOutAlpha = C.DB.actionbar.pet_bar_fade_out_alpha,
			arena = C.DB.actionbar.pet_bar_fade_arena,
			instance = C.DB.actionbar.pet_bar_fade_instance,
			combat = C.DB.actionbar.pet_bar_fade_combat,
			target = C.DB.actionbar.pet_bar_fade_target,
			hover = C.DB.actionbar.pet_bar_fade_hover,
		}

		ACTIONBAR.CreateButtonFrameFader(frame, buttonList, frame.fader)
	end
end

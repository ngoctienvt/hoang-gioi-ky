extends RefCounted
## Centralized Dark Xianxia (Ink / Jade / Aged Gold / Cinnabar) theme and color palette.

const BG_DEEP := Color(0.043, 0.063, 0.060, 0.92)
const BG_CARD := Color(0.086, 0.122, 0.114, 0.92)
const BG_ELEVATED := Color(0.118, 0.165, 0.153, 0.96)
const BG_HOVER := Color(0.173, 0.235, 0.212, 0.98)
const BG_PRESSED := Color(0.133, 0.247, 0.204, 0.98)
const BG_DISABLED := Color(0.075, 0.090, 0.088, 0.65)
const BG_PRIMARY_BTN := Color(0.145, 0.275, 0.220, 0.96)
const BG_PRIMARY_HOVER := Color(0.195, 0.345, 0.278, 0.98)
const BG_DANGER_BTN := Color(0.280, 0.105, 0.100, 0.94)
const BG_DANGER_HOVER := Color(0.380, 0.140, 0.130, 0.98)

const BORDER_GOLD := Color("b69352")
const BORDER_GOLD_DIM := Color(0.56, 0.46, 0.27, 0.65)
const BORDER_JADE := Color("89c4a6")
const BORDER_DANGER := Color("c4544c")

const TEXT_PRIMARY := Color("f2e6c9")
const TEXT_MUTED := Color("a7a18d")
const TEXT_GOOD := Color("8ed19d")
const TEXT_BAD := Color("e37b72")
const TEXT_ACCENT := Color("e6c473")
const TEXT_WARN := Color("e6b85c")


static func _make_box(bg: Color, border: Color, border_w: int = 1, radius: int = 6, pad_h: int = 10, pad_v: int = 7, shadow: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	if shadow > 0:
		sb.shadow_size = shadow
		sb.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
		sb.shadow_offset = Vector2(0, 2)
	return sb


static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 14

	# Base PanelContainer
	t.set_stylebox("panel", "PanelContainer", _make_box(BG_DEEP, BORDER_GOLD_DIM, 1, 8, 12, 10, 6))

	# Panel variations
	t.set_type_variation("PanelPrimary", "PanelContainer")
	t.set_stylebox("panel", "PanelPrimary", _make_box(BG_DEEP, BORDER_GOLD, 1, 8, 12, 10, 6))

	t.set_type_variation("PanelCard", "PanelContainer")
	t.set_stylebox("panel", "PanelCard", _make_box(BG_CARD, BORDER_GOLD_DIM, 1, 6, 10, 8, 2))

	t.set_type_variation("PanelPill", "PanelContainer")
	t.set_stylebox("panel", "PanelPill", _make_box(BG_DEEP, BORDER_GOLD_DIM, 1, 14, 12, 5, 4))

	t.set_type_variation("PanelModal", "PanelContainer")
	t.set_stylebox("panel", "PanelModal", _make_box(Color(0.047, 0.071, 0.067, 0.97), BORDER_GOLD, 2, 10, 18, 16, 12))

	# Base Button
	t.set_stylebox("normal", "Button", _make_box(BG_CARD, BORDER_GOLD_DIM, 1, 6, 10, 6, 2))
	t.set_stylebox("hover", "Button", _make_box(BG_HOVER, BORDER_GOLD, 1, 6, 10, 6, 3))
	t.set_stylebox("pressed", "Button", _make_box(BG_PRESSED, BORDER_JADE, 1, 6, 10, 6, 1))
	t.set_stylebox("disabled", "Button", _make_box(BG_DISABLED, Color(0.35, 0.32, 0.25, 0.35), 1, 6, 10, 6, 0))
	var focus_sb := StyleBoxFlat.new()
	focus_sb.bg_color = Color.TRANSPARENT
	focus_sb.border_color = BORDER_JADE
	focus_sb.set_border_width_all(2)
	focus_sb.set_corner_radius_all(6)
	t.set_stylebox("focus", "Button", focus_sb)
	t.set_color("font_color", "Button", TEXT_PRIMARY)
	t.set_color("font_hover_color", "Button", Color("fff4d6"))
	t.set_color("font_pressed_color", "Button", TEXT_JADE_OR_PRIMARY())
	t.set_color("font_disabled_color", "Button", Color(0.60, 0.58, 0.50, 0.55))

	# ButtonPrimary
	t.set_type_variation("ButtonPrimary", "Button")
	t.set_stylebox("normal", "ButtonPrimary", _make_box(BG_PRIMARY_BTN, BORDER_GOLD, 1, 6, 14, 8, 4))
	t.set_stylebox("hover", "ButtonPrimary", _make_box(BG_PRIMARY_HOVER, Color("d8b467"), 1, 6, 14, 8, 5))
	t.set_stylebox("pressed", "ButtonPrimary", _make_box(BG_PRESSED, BORDER_JADE, 1, 6, 14, 8, 1))
	t.set_color("font_color", "ButtonPrimary", Color("fff3d4"))

	# ButtonSubtle
	t.set_type_variation("ButtonSubtle", "Button")
	t.set_stylebox("normal", "ButtonSubtle", _make_box(Color(0.09, 0.13, 0.12, 0.55), Color(0.56, 0.46, 0.27, 0.35), 1, 6, 8, 4, 0))
	t.set_stylebox("hover", "ButtonSubtle", _make_box(BG_HOVER, BORDER_GOLD_DIM, 1, 6, 8, 4, 2))
	t.set_stylebox("pressed", "ButtonSubtle", _make_box(BG_PRESSED, BORDER_JADE, 1, 6, 8, 4, 0))

	# ButtonDanger
	t.set_type_variation("ButtonDanger", "Button")
	t.set_stylebox("normal", "ButtonDanger", _make_box(BG_DANGER_BTN, BORDER_DANGER, 1, 6, 12, 7, 2))
	t.set_stylebox("hover", "ButtonDanger", _make_box(BG_DANGER_HOVER, Color("e37b72"), 1, 6, 12, 7, 4))
	t.set_stylebox("pressed", "ButtonDanger", _make_box(Color(0.22, 0.08, 0.08, 0.96), BORDER_DANGER, 1, 6, 12, 7, 0))
	t.set_color("font_color", "ButtonDanger", Color("ffd8d4"))

	# ButtonIcon
	t.set_type_variation("ButtonIcon", "Button")
	t.set_stylebox("normal", "ButtonIcon", _make_box(BG_CARD, BORDER_GOLD_DIM, 1, 8, 6, 6, 2))
	t.set_stylebox("hover", "ButtonIcon", _make_box(BG_HOVER, BORDER_GOLD, 1, 8, 6, 6, 3))
	t.set_stylebox("pressed", "ButtonIcon", _make_box(BG_PRESSED, BORDER_JADE, 2, 8, 6, 6, 1))

	# Labels
	t.set_color("font_color", "Label", TEXT_PRIMARY)
	t.set_type_variation("LabelTitle", "Label")
	t.set_color("font_color", "LabelTitle", TEXT_ACCENT)
	t.set_font_size("font_size", "LabelTitle", 22)

	t.set_type_variation("LabelHeading", "Label")
	t.set_color("font_color", "LabelHeading", TEXT_ACCENT)
	t.set_font_size("font_size", "LabelHeading", 16)

	t.set_type_variation("LabelMuted", "Label")
	t.set_color("font_color", "LabelMuted", TEXT_MUTED)
	t.set_font_size("font_size", "LabelMuted", 12)

	# LineEdit
	t.set_stylebox("normal", "LineEdit", _make_box(Color(0.035, 0.052, 0.050, 0.95), BORDER_GOLD_DIM, 1, 6, 10, 6, 0))
	t.set_stylebox("focus", "LineEdit", _make_box(Color(0.045, 0.070, 0.066, 0.98), BORDER_JADE, 1, 6, 10, 6, 0))
	t.set_color("font_color", "LineEdit", TEXT_PRIMARY)
	t.set_color("font_placeholder_color", "LineEdit", Color(0.65, 0.62, 0.54, 0.55))
	t.set_color("caret_color", "LineEdit", TEXT_ACCENT)

	# ProgressBar
	t.set_stylebox("background", "ProgressBar", _make_box(Color(0.03, 0.045, 0.043, 0.95), Color(0.40, 0.34, 0.22, 0.55), 1, 4, 0, 0, 0))
	t.set_stylebox("fill", "ProgressBar", _make_box(Color("b44d48"), Color.TRANSPARENT, 0, 3, 0, 0, 0))

	# HSlider
	t.set_stylebox("slider", "HSlider", _make_box(Color(0.04, 0.06, 0.058, 0.95), BORDER_GOLD_DIM, 1, 4, 0, 3, 0))
	t.set_stylebox("grabber_area", "HSlider", _make_box(Color("89c4a6"), Color.TRANSPARENT, 0, 4, 0, 3, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", _make_box(BORDER_GOLD, Color.TRANSPARENT, 0, 4, 0, 3, 0))

	# CheckButton
	t.set_color("font_color", "CheckButton", TEXT_PRIMARY)
	t.set_color("font_hover_color", "CheckButton", Color("fff4d6"))

	# OptionButton & SpinBox
	t.set_stylebox("normal", "OptionButton", _make_box(BG_CARD, BORDER_GOLD_DIM, 1, 6, 10, 6, 1))
	t.set_stylebox("hover", "OptionButton", _make_box(BG_HOVER, BORDER_GOLD, 1, 6, 10, 6, 2))
	t.set_stylebox("pressed", "OptionButton", _make_box(BG_PRESSED, BORDER_JADE, 1, 6, 10, 6, 0))
	t.set_color("font_color", "OptionButton", TEXT_PRIMARY)

	# PopupMenu (for OptionButton dropdown)
	t.set_stylebox("panel", "PopupMenu", _make_box(BG_ELEVATED, BORDER_GOLD, 1, 6, 6, 6, 8))
	t.set_stylebox("hover", "PopupMenu", _make_box(BG_HOVER, BORDER_GOLD_DIM, 1, 4, 6, 4, 0))
	t.set_color("font_color", "PopupMenu", TEXT_PRIMARY)
	t.set_color("font_hover_color", "PopupMenu", Color("fff4d6"))

	# TooltipPanel
	t.set_stylebox("panel", "TooltipPanel", _make_box(Color(0.038, 0.058, 0.055, 0.97), BORDER_GOLD, 1, 6, 10, 7, 6))
	t.set_color("font_color", "TooltipLabel", TEXT_PRIMARY)
	t.set_font_size("font_size", "TooltipLabel", 13)

	# VScrollBar
	t.set_stylebox("scroll", "VScrollBar", _make_box(Color(0.03, 0.045, 0.043, 0.6), Color.TRANSPARENT, 0, 4, 3, 0, 0))
	t.set_stylebox("grabber", "VScrollBar", _make_box(Color(0.56, 0.46, 0.27, 0.6), Color.TRANSPARENT, 0, 4, 0, 0, 0))
	t.set_stylebox("grabber_highlight", "VScrollBar", _make_box(BORDER_GOLD, Color.TRANSPARENT, 0, 4, 0, 0, 0))
	t.set_stylebox("grabber_pressed", "VScrollBar", _make_box(BORDER_JADE, Color.TRANSPARENT, 0, 4, 0, 0, 0))

	return t


static func TEXT_JADE_OR_PRIMARY() -> Color:
	return Color("b8ebd0")

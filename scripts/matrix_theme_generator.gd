@tool
extends ProgrammaticTheme

var background_color := Color("#030303")
var text_color := Color("#1CA152")
var button_color := Color("#008529")
var margin := 30


func setup():
	set_save_path("res://themes/generated/matrix_theme.tres")

func define_theme():
	define_default_font_size(26)
	define_style("Label", {
		font_color = text_color
	})
	
	var panel_style = stylebox_flat({
		bg_color = background_color,
		font_color = text_color,
	})
	
	var window_style = stylebox_flat({
		bg_color = button_color,
		expand_margin_top = 36,
	})
	
	var button_style = stylebox_flat({
		bg_color = button_color,
		font_color = text_color,
	})
	
	var button_hover_style = inherit(button_style, {
		bg_color = button_color.darkened(0.1)
	})
	
	define_style("Button", {
		align_to_largest_stylebox = 1,
		normal = button_style,
		hover = button_hover_style
	})
	
	define_style("Panel", {
		panel = panel_style
	})
	
	define_style("MarginContainer", {
		margin_left = margin,
		margin_top = margin,
		margin_right = margin,
		margin_bottom = margin,
	})
	
	define_style("BoxContainer", {
		separation = margin
	})
	
	define_style("Window", {
		embedded_border = window_style,
	})

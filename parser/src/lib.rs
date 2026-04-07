use kdl::{KdlDocument, KdlNode};
use serde::{Deserialize, Serialize};
use wasm_bindgen::{JsError, JsValue, prelude::wasm_bindgen};

#[derive(Serialize, Deserialize, Debug)]
pub struct Binding {
    key: String,
    modifiers: Vec<Modifier>,
    actions: Vec<String>,
    options: Vec<(String, String)>,
}

#[derive(Serialize, Deserialize, Debug, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum Modifier {
    Ctrl,
    Control,
    Mod,
    Alt,
    Super,
    Win,
    Shift,
    Mod3,
    Mod5,
    #[serde(rename = "ISO_Level3_Shift")]
    ISOLevel3Shift,
    #[serde(rename = "ISO_Level5_Shift")]
    ISOLevel5Shift,
}

#[wasm_bindgen]
pub fn parse_config(config: &str) -> Result<JsValue, JsError> {
    let doc: KdlDocument = config
        .parse()
        .map_err(|e| JsError::new(format!("KDL Parse Error: {}", e).as_str()))?;

    let mut bindings: Vec<Binding> = Vec::new();

    if let Some(binds_node) = doc.nodes().iter().find(|n| n.name().value() == "binds") {
        if let Some(entries) = binds_node.children() {
            for node in entries.nodes() {
                bindings.push(parse_single_bind(node));
            }
        }
    }

    serde_wasm_bindgen::to_value(&bindings)
        .map_err(|e| JsError::new(format!("Serde Error: {}", e).as_str()))
}

fn parse_single_bind(node: &KdlNode) -> Binding {
    let raw_combo = node.name().value().to_string();
    let parts: Vec<&str> = raw_combo.split('+').collect();

    let mut modifiers = Vec::new();
    let mut key = String::new();

    for (i, part) in parts.iter().enumerate() {
        if i == parts.len() - 1 {
            key = part.to_string().to_lowercase();
        } else {
            if let Some(m) = map_modifier(part) {
                modifiers.push(m)
            }
        }
    }

    let mut actions = Vec::new();
    if let Some(children) = node.children() {
        for action_node in children.nodes() {
            let name = action_node.name().value();
            let args: Vec<String> = action_node
                .entries()
                .iter()
                .filter(|e| e.name().is_none())
                .map(|e| e.value().to_string().replace('"', ""))
                .collect();

            actions.push(format!("{} {}", name, args.join(" ")).trim().to_string());
        }
    }

    let options = node
        .entries()
        .iter()
        .filter_map(|entry| {
            entry.name().map(|n| {
                let k = n.value().to_string();
                let mut v = entry.value().to_string().replace('"', "");
                if v == "#true" {
                    v = "true".to_string();
                } else if v == "#false" {
                    v = "false".to_string();
                }
                (k, v)
            })
        })
        .collect();

    Binding {
        key,
        modifiers,
        actions,
        options,
    }
}

fn map_modifier(m: &str) -> Option<Modifier> {
    match m.to_lowercase().as_str() {
        "ctrl" => Some(Modifier::Ctrl),
        "control" => Some(Modifier::Control),
        "mod" => Some(Modifier::Mod),
        "mod3" => Some(Modifier::Mod3),
        "alt" => Some(Modifier::Alt),
        "super" => Some(Modifier::Super),
        "win" => Some(Modifier::Win),
        "shift" => Some(Modifier::Shift),
        "mod5" => Some(Modifier::Mod5),
        "iso_level3_shift" => Some(Modifier::ISOLevel3Shift),
        "iso_level5_shift" => Some(Modifier::ISOLevel5Shift),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_modifier_mapping() {
        assert_eq!(map_modifier("Mod"), Some(Modifier::Mod));
        assert_eq!(map_modifier("Super"), Some(Modifier::Super));
        assert_eq!(map_modifier("ctrl"), Some(Modifier::Ctrl));
        assert_eq!(map_modifier("not-a-mod"), None);
    }

    #[test]
    fn test_parse_complex_binding() {
        let kdl_str = r#"binds {
            Mod+Shift+Slash hotkey-overlay-title="Show Help" { show-hotkey-overlay; }
        }"#;

        let doc: KdlDocument = kdl_str.parse().unwrap();
        let binds_node = doc.nodes().first().unwrap();
        let bind_node = binds_node.children().unwrap().nodes().first().unwrap();

        let result = parse_single_bind(bind_node);

        assert_eq!(result.key, "Slash");
        assert_eq!(result.modifiers, vec![Modifier::Mod, Modifier::Shift]);
        assert_eq!(result.actions, vec!["show-hotkey-overlay"]);

        let title_opt = result
            .options
            .iter()
            .find(|(k, _)| k == "hotkey-overlay-title");
        assert_eq!(title_opt.unwrap().1, "Show Help");
    }

    #[test]
    fn test_parse_full_niri_config() {
        let kdl_str = r#"binds {
    Mod+Shift+Slash { show-hotkey-overlay; }

    Mod+Return hotkey-overlay-title="Open a Terminal: Alacritty" { spawn "alacritty"; }
    Mod+D hotkey-overlay-title="Run an Application: rofi" { spawn-sh "rofi -show drun -show-icons"; }
    Super+Alt+L hotkey-overlay-title="Lock the Screen: swaylock" { spawn "swaylock"; }


    XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+"; }
    XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
    XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
    XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }

    XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
    XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }

    Mod+O repeat=false { toggle-overview; }

    Mod+Shift+C repeat=false { close-window; }

    Mod+Ctrl+Left  { move-column-left; }
    Mod+Ctrl+Down  { move-window-down; }
    Mod+Ctrl+Up    { move-window-up; }
    Mod+Ctrl+Right { move-column-right; }
    Mod+Ctrl+H     { move-column-left; }
    Mod+Ctrl+L     { move-column-right; }

    Mod+Ctrl+J     { move-window-down-or-to-workspace-down; }
    Mod+Ctrl+K     { move-window-up-or-to-workspace-up; }

    Mod+Home { focus-column-first; }
    Mod+End  { focus-column-last; }
    Mod+Ctrl+Home { move-column-to-first; }
    Mod+Ctrl+End  { move-column-to-last; }

    Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
    Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
    Mod+Shift+Ctrl+Up    { move-column-to-monitor-up; }
    Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
    Mod+Shift+Ctrl+H     { move-column-to-monitor-left; }
    Mod+Shift+Ctrl+J     { move-column-to-monitor-down; }
    Mod+Shift+Ctrl+K     { move-column-to-monitor-up; }
    Mod+Shift+Ctrl+L     { move-column-to-monitor-right; }

    Mod+Page_Down      { focus-workspace-down; }
    Mod+Page_Up        { focus-workspace-up; }
    Mod+U              { focus-workspace-down; }
    Mod+I              { focus-workspace-up; }
    Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
    Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }
    Mod+Ctrl+U         { move-column-to-workspace-down; }
    Mod+Ctrl+I         { move-column-to-workspace-up; }

    Mod+Shift+Page_Down { move-workspace-down; }
    Mod+Shift+Page_Up   { move-workspace-up; }
    Mod+Shift+U         { move-workspace-down; }
    Mod+Shift+I         { move-workspace-up; }

    Mod+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
    Mod+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; }
    Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
    Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }

    Mod+Ctrl+WheelScrollLeft  { move-column-left; }

    Mod+Shift+WheelScrollDown      { focus-column-right; }
    Mod+Shift+WheelScrollUp        { focus-column-left; }
    Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
    Mod+Ctrl+Shift+WheelScrollUp   { move-column-left; }

    Mod+a { focus-workspace 1; }
    Mod+s { focus-workspace 2; }
    Mod+3 { focus-workspace 3; }
    Mod+Shift+7 { move-column-to-workspace 7; }
    Mod+Shift+8 { move-column-to-workspace 8; }
    Mod+Shift+9 { move-column-to-workspace 9; }

    Mod+Comma { consume-or-expel-window-left; }
    Mod+Period { consume-or-expel-window-right; }

    Mod+BracketLeft  { consume-window-into-column; }
    Mod+BracketRight { expel-window-from-column; }

    Mod+R { switch-preset-column-width; }
    Mod+Shift+R { switch-preset-window-height; }
    Mod+Ctrl+R { reset-window-height; }
    Mod+F { maximize-column; }
    Mod+Shift+F { fullscreen-window; }

    Mod+Ctrl+F { expand-column-to-available-width; }

    Mod+C { center-column; }

    Mod+Ctrl+C { center-visible-columns; }

    Mod+Minus { set-column-width "-10%"; }
    Mod+Equal { set-column-width "+10%"; }

    Mod+Shift+Minus { set-window-height "-10%"; }
    Mod+Shift+Equal { set-window-height "+10%"; }
    Mod+Shift+V { switch-focus-between-floating-and-tiling; }

    Mod+W { toggle-column-tabbed-display; }

    Print { screenshot; }
    Ctrl+Print { screenshot-screen; }
    Alt+Print { screenshot-window; }

    Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }

    Mod+Shift+E { quit; }
    Ctrl+Alt+Delete { quit; }

    Mod+Shift+P { power-off-monitors; }

    Alt+q hotkey-overlay-title="Open wiremix in a floating window" { spawn "alacritty" "--class='floating-terminal'" "-e" "wiremix"; }
    Mod+Shift+n hotkey-overlay-title="Open rmpc" { spawn "alacritty" "--class='music-player'" "-e" "rmpc"; }

    Mod+Ctrl+Shift+F { toggle-windowed-fullscreen; }
}
"#;

        let doc: KdlDocument = kdl_str.parse().unwrap();
        let binds_node = doc.nodes().first().unwrap();
        let children = binds_node.children().unwrap();

        let bindings: Vec<Binding> = children.nodes().iter().map(parse_single_bind).collect();

        let terminal = bindings.iter().find(|b| b.key == "Return").unwrap();
        assert_eq!(terminal.modifiers, vec![Modifier::Mod]);
        assert_eq!(terminal.actions, vec!["spawn alacritty"]);
        assert_eq!(
            terminal
                .options
                .iter()
                .find(|(k, _)| k == "hotkey-overlay-title")
                .unwrap()
                .1,
            "Open a Terminal: Alacritty"
        );

        let brightness = bindings
            .iter()
            .find(|b| b.key == "XF86MonBrightnessUp")
            .unwrap();
        assert!(brightness.modifiers.is_empty());
        assert_eq!(
            brightness.actions,
            vec!["spawn brightnessctl --class=backlight set +10%"]
        );
        assert_eq!(
            brightness
                .options
                .iter()
                .find(|(k, _)| k == "allow-when-locked")
                .unwrap()
                .1,
            "true"
        );

        let workspace_3 = bindings.iter().find(|b| b.key == "3").unwrap();
        assert_eq!(workspace_3.modifiers, vec![Modifier::Mod]);
        assert_eq!(workspace_3.actions, vec!["focus-workspace 3"]);

        let repeat_opt = bindings.iter().find(|b| b.key == "O").unwrap();
        assert_eq!(
            repeat_opt
                .options
                .iter()
                .find(|(k, _)| k == "repeat")
                .unwrap()
                .1,
            "false"
        );
    }
}

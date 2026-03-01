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
            key = part.to_string();
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
        "alt" => Some(Modifier::Alt),
        "super" => Some(Modifier::Super),
        "win" => Some(Modifier::Win),
        "shift" => Some(Modifier::Shift),
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
    fn test_parse_xf86_no_modifiers() {
        let kdl_str = r#"binds {
           XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
        }"#;

        let doc: KdlDocument = kdl_str.parse().unwrap();
        let binds_node = doc.nodes().first().unwrap();
        let bind_node = binds_node.children().unwrap().nodes().first().unwrap();

        let result = parse_single_bind(bind_node);

        assert_eq!(result.key, "XF86MonBrightnessUp");
        assert!(result.modifiers.is_empty());
        assert_eq!(result.actions, vec!["spawn brightnessctl --class=backlight set +10%"]);

        let lock_opt = result
            .options
            .iter()
            .find(|(k, _)| k == "allow-when-locked");
        assert_eq!(lock_opt.unwrap().1, "true");
    }
}

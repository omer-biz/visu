import init, { parse_config } from "../parser/pkg/parser.js";

self.onmessage = async (e) => {
  await init();

  try {
    const result = parse_config(e.data);
    self.postMessage({ type: "SUCCESS", data: result });
  } catch (err) {
    self.postMessage({ type: "ERROR", error: err });
  }
}

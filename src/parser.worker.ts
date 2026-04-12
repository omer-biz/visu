import init, { parse_config, extract_includes } from "../parser/pkg/parser.js";

self.onmessage = async (e) => {
  await init();

  try {
    let files: Array<{ path: string, content: string }> = [];
    if (typeof e.data === "string") {
      files = [{ path: "config.kdl", content: e.data }];
    } else if (e.data && e.data.type === "FOLDER") {
      files = e.data.files;
    }

    if (files.length === 0) {
      throw new Error("No files uploaded");
    }

    const rootFile = files.find(f => f.path.endsWith('/config.kdl') || f.path === 'config.kdl') || files[0];

    // We will build a map of { [filename]: Binding[] }
    const resultGraph: Record<string, any> = {};

    function processFile(fileObj: { path: string, content: string }) {
      if (resultGraph[fileObj.path]) return; // Avoid circular includes

      const parsed = parse_config(fileObj.content);
      resultGraph[fileObj.path] = parsed;

      try {
        const includes = extract_includes(fileObj.content) as string[];
        for (const inc of includes) {
          const fileMatch = files.find(f => f.path.endsWith(inc));
          if (fileMatch) {
            processFile(fileMatch);
          }
        }
      } catch (err) {
        console.warn("Failed to extract includes from", fileObj.path, err);
      }
    }

    processFile(rootFile);

    self.postMessage({ type: "SUCCESS", data: resultGraph });
  } catch (err) {
    self.postMessage({ type: "ERROR", error: String(err) });
  }
}

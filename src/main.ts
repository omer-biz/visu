import './style.css'
import { Elm } from "./Main.elm";

const worker = new Worker(
  new URL("./parser.worker.ts", import.meta.url),
  { type: "module" }
);

const app = Elm.Main.init({
  node: document.getElementById("app")
});

app.ports.sendConfig.subscribe((configStr: string) => worker.postMessage(configStr));
worker.onmessage = (e) => app.ports.receiveParsed.send(e.data);

document.addEventListener("change", async (e: Event) => {
  const target = e.target as HTMLInputElement;

  if (target && target.type === "file" && (target.id === "folder-upload" || target.id === "file-upload") && target.files) {
    const filesArray = Array.from(target.files);

    // We send Parsing state directly via port since we bypassed Elm's standard file handler
    app.ports.receiveParsed.send({ type: "PARSING_STATE" });

    const fileDataPromises = filesArray.map(async (file) => {
      const content = await file.text();
      const relativePath = file.webkitRelativePath || file.name;
      return { path: relativePath, content };
    });

    const files = await Promise.all(fileDataPromises);
    worker.postMessage({ type: "FOLDER", files });
  }
});

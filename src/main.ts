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

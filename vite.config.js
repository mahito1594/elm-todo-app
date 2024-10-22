import { defineConfig } from "vite";
import elmPlugin from "vite-plugin-elm";

const REPO_NAME = "elm-todo-app";

export default defineConfig({
  plugins: [elmPlugin()],
  base: `/${REPO_NAME}/`,
});

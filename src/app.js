import "@picocss/pico";
import { addTodo, deleteTodo, getAllTodos, updateTodo } from "./repository";
import { Elm } from "./Main.elm";

const main = async () => {
  const savedTodos = await getAllTodos();
  const app = Elm.Main.init({
    node: document.getElementById("app"),
    flags: savedTodos,
  });

  app.ports.addNewTodoItem.subscribe(async (todo) => {
    const id = await addTodo(todo);
    app.ports.newItemReciever.send({ ...todo, id });
  });

  app.ports.toggleStatus.subscribe(async (todo) => {
    const id = await updateTodo(todo);
    app.ports.toggleStatusReciever.send(id);
  });

  app.ports.deleteTodoItem.subscribe(async (id) => {
    await deleteTodo(id);
  });
};

main();

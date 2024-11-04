import { openDB } from "idb";

const useDB = async () => {
  const db = await openDB("todo-store", 1, {
    upgrade(db) {
      db.createObjectStore("todos", { keyPath: "id", autoIncrement: true });
    },
  });
  return db;
};

/**
 * @typedef {Object} Todo
 * @property {number=} id
 * @property {string} description
 * @property {boolean} done
 */

/**
 * Get all todos from the database
 *
 * @returns {Promise<Todo[]>} List of all todos
 */
export const getAllTodos = async () => {
  const db = await useDB();
  return db.getAll("todos");
};

/**
 * Add a new todo to the database
 *
 * @param {Todo} todo Todo item to add (without id)
 * @returns {Promise<number>} id of the new todo
 */
export const addTodo = async (todo) => {
  const db = await useDB();
  return db.add("todos", todo);
};

/**
 * Delete a todo from the database
 *
 * @param {number} id id of the todo to delete
 */
export const deleteTodo = async (id) => {
  const db = await useDB();
  return db.delete("todos", id);
};

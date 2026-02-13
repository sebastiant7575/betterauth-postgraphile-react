import { createFileRoute } from "@tanstack/react-router";
import { gql, useQuery, useMutation } from "@apollo/client";
import { useState } from "react";

const ALL_NOTES = gql`
  query AllNotes {
    allNotes(orderBy: CREATED_AT_DESC) {
      nodes {
        id
        title
        body
        createdAt
        updatedAt
      }
    }
  }
`;

const CREATE_NOTE = gql`
  mutation CreateNote($input: CreateNoteInput!) {
    createNote(input: $input) {
      note {
        id
        title
        body
        createdAt
        updatedAt
      }
    }
  }
`;

const UPDATE_NOTE = gql`
  mutation UpdateNote($id: Int!, $patch: NotePatch!) {
    updateNoteById(input: { id: $id, patch: $patch }) {
      note {
        id
        title
        body
        updatedAt
      }
    }
  }
`;

const DELETE_NOTE = gql`
  mutation DeleteNote($id: Int!) {
    deleteNoteById(input: { id: $id }) {
      deletedNoteNodeId
    }
  }
`;

interface Note {
  id: number;
  title: string;
  body: string;
  createdAt: string;
  updatedAt: string;
}

export const Route = createFileRoute("/_authenticated/notes")({
  component: NotesPage,
});

function NotesPage() {
  const { data, loading, refetch } = useQuery(ALL_NOTES, {
    fetchPolicy: "network-only",
  });
  const [createNote] = useMutation(CREATE_NOTE);
  const [updateNote] = useMutation(UPDATE_NOTE);
  const [deleteNote] = useMutation(DELETE_NOTE);

  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [editingId, setEditingId] = useState<number | null>(null);

  const notes: Note[] = data?.allNotes?.nodes ?? [];

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;

    if (editingId) {
      await updateNote({
        variables: { id: editingId, patch: { title, body } },
      });
      setEditingId(null);
    } else {
      await createNote({
        variables: { input: { note: { title, body } } },
      });
    }
    setTitle("");
    setBody("");
    refetch();
  };

  const handleEdit = (note: Note) => {
    setEditingId(note.id);
    setTitle(note.title);
    setBody(note.body);
  };

  const handleDelete = async (id: number) => {
    await deleteNote({ variables: { id } });
    refetch();
  };

  const handleCancel = () => {
    setEditingId(null);
    setTitle("");
    setBody("");
  };

  return (
    <div className="max-w-2xl mx-auto mt-10">
      <h1 className="text-2xl font-bold mb-6">My Notes</h1>

      <form onSubmit={handleSubmit} className="bg-white rounded-lg shadow p-4 mb-8 space-y-3">
        <input
          type="text"
          placeholder="Title"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          className="w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo-500"
        />
        <textarea
          placeholder="Body"
          value={body}
          onChange={(e) => setBody(e.target.value)}
          rows={3}
          className="w-full border border-gray-300 rounded px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo-500"
        />
        <div className="flex gap-2">
          <button
            type="submit"
            className="bg-indigo-600 text-white px-4 py-2 rounded hover:bg-indigo-700 transition"
          >
            {editingId ? "Update" : "Create"}
          </button>
          {editingId && (
            <button
              type="button"
              onClick={handleCancel}
              className="bg-gray-200 text-gray-700 px-4 py-2 rounded hover:bg-gray-300 transition"
            >
              Cancel
            </button>
          )}
        </div>
      </form>

      {loading ? (
        <p className="text-gray-500">Loading...</p>
      ) : notes.length === 0 ? (
        <p className="text-gray-500">No notes yet. Create your first one!</p>
      ) : (
        <div className="space-y-4">
          {notes.map((note) => (
            <div
              key={note.id}
              className="bg-white rounded-lg shadow p-4 flex justify-between items-start"
            >
              <div className="flex-1 min-w-0">
                <h2 className="font-semibold text-lg">{note.title}</h2>
                {note.body && (
                  <p className="text-gray-600 mt-1 whitespace-pre-wrap">
                    {note.body}
                  </p>
                )}
                <p className="text-xs text-gray-400 mt-2">
                  {new Date(note.createdAt).toLocaleString()}
                </p>
              </div>
              <div className="flex gap-2 ml-4 shrink-0">
                <button
                  onClick={() => handleEdit(note)}
                  className="text-indigo-600 hover:text-indigo-800 text-sm font-medium"
                >
                  Edit
                </button>
                <button
                  onClick={() => handleDelete(note.id)}
                  className="text-red-600 hover:text-red-800 text-sm font-medium"
                >
                  Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

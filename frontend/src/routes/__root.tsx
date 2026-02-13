import { createRootRoute, Link, Outlet } from "@tanstack/react-router";
import { authClient } from "../lib/auth-client";

export const Route = createRootRoute({
  component: RootLayout,
});

function RootLayout() {
  const { data: session } = authClient.useSession();

  return (
    <div className="min-h-screen flex flex-col">
      <nav className="bg-white shadow px-6 py-3 flex items-center justify-between">
        <Link to="/" className="text-xl font-bold text-indigo-600">
          Notes
        </Link>
        <div className="flex gap-4 items-center">
          {session ? (
            <>
              <Link
                to="/dashboard"
                className="text-gray-700 hover:text-indigo-600"
              >
                Dashboard
              </Link>
              <Link
                to="/notes"
                className="text-gray-700 hover:text-indigo-600"
              >
                My Notes
              </Link>
            </>
          ) : (
            <Link
              to="/login"
              className="text-gray-700 hover:text-indigo-600"
            >
              Login
            </Link>
          )}
        </div>
      </nav>
      <main className="flex-1 p-6">
        <Outlet />
      </main>
    </div>
  );
}

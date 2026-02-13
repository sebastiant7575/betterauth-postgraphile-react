import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useApolloClient } from "@apollo/client";
import { authClient } from "../../lib/auth-client";

export const Route = createFileRoute("/_authenticated/dashboard")({
  component: DashboardPage,
});

function DashboardPage() {
  const { data: session } = authClient.useSession();
  const navigate = useNavigate();
  const apolloClient = useApolloClient();

  const handleSignOut = async () => {
    await authClient.signOut();
    await apolloClient.resetStore();
    navigate({ to: "/" });
  };

  if (!session) return null;

  return (
    <div className="max-w-lg mx-auto mt-10">
      <h1 className="text-2xl font-bold mb-6">Dashboard</h1>
      <div className="bg-white rounded-lg shadow p-6 space-y-3">
        {session.user.image && (
          <img
            src={session.user.image}
            alt=""
            className="w-16 h-16 rounded-full"
          />
        )}
        <p>
          <span className="font-medium">Name:</span> {session.user.name}
        </p>
        <p>
          <span className="font-medium">Email:</span> {session.user.email}
        </p>
        <div>
          <span className="font-medium">Session Token:</span>
          <pre className="mt-1 bg-gray-100 p-3 rounded text-xs break-all whitespace-pre-wrap max-h-40 overflow-auto">
            {session.session.token}
          </pre>
        </div>
        <button
          onClick={handleSignOut}
          className="mt-4 bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition"
        >
          Sign Out
        </button>
      </div>
    </div>
  );
}

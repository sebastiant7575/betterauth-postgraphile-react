import { createFileRoute, Link } from "@tanstack/react-router";

export const Route = createFileRoute("/")({
  component: LandingPage,
});

function LandingPage() {
  return (
    <div className="max-w-2xl mx-auto text-center mt-20">
      <h1 className="text-4xl font-bold text-gray-900 mb-4">
        Your Notes, Secured
      </h1>
      <p className="text-lg text-gray-600 mb-8">
        A fullstack notes app with Google &amp; GitHub SSO, GraphQL API, and
        row-level security. Only you can see your notes.
      </p>
      <Link
        to="/login"
        className="inline-block bg-indigo-600 text-white px-6 py-3 rounded-lg font-medium hover:bg-indigo-700 transition"
      >
        Get Started
      </Link>
    </div>
  );
}

import { postgraphile } from "postgraphile";
import { auth } from "./auth.js";
import { fromNodeHeaders } from "better-auth/node";
import type { IncomingMessage } from "http";

const DATABASE_URL = process.env.DATABASE_URL!;
const POSTGRAPHILE_URL = DATABASE_URL.replace(
  /\/\/[^@]+@/,
  "//app_postgraphile:postgraphile_pass@"
);

export const postgraphileMiddleware = postgraphile(POSTGRAPHILE_URL, "app_public", {
  watchPg: true,
  ownerConnectionString: DATABASE_URL,
  graphiql: true,
  enhanceGraphiql: true,
  dynamicJson: true,
  setofFunctionsContainNulls: false,
  ignoreRBAC: true,
  pgSettings: async (req: IncomingMessage) => {
    try {
      const session = await auth.api.getSession({
        headers: fromNodeHeaders(req.headers),
      });

      if (session?.user) {
        return {
          role: "app_authenticated",
          "jwt.claims.user_id": session.user.id,
        };
      }
    } catch {
      // No valid session
    }

    return {
      role: "app_anonymous",
    };
  },
});

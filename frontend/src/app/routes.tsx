import { createBrowserRouter } from "react-router";
import { lazy } from "react";

const Splash = lazy(() => import("./screens/Splash"));
const TrendsLoading = lazy(() => import("./screens/TrendsLoading"));
const TrendsResults = lazy(() => import("./screens/TrendsResults"));
const Dashboard = lazy(() => import("./screens/Dashboard"));
const Outreach = lazy(() => import("./screens/Outreach"));

export const router = createBrowserRouter([
  {
    path: "/",
    Component: Splash,
  },
  {
    path: "/trends/loading",
    Component: TrendsLoading,
  },
  {
    path: "/trends/results",
    Component: TrendsResults,
  },
  {
    path: "/dashboard",
    Component: Dashboard,
  },
  {
    path: "/outreach",
    Component: Outreach,
  },
]);

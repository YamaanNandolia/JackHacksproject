import { useEffect, useRef } from "react";
import { useNavigate } from "react-router";
import { useApp } from "../context/AppContext";
import { fetchTrendClusters } from "@/services/api";

export default function TrendsLoading() {
  const navigate = useNavigate();
  const { setTrendClusters } = useApp();
  const started = useRef(false);

  useEffect(() => {
    if (started.current) return;
    started.current = true;

    fetchTrendClusters()
      .then((clusters) => {
        setTrendClusters(clusters);
        navigate("/trends/results");
      })
      .catch((err) => {
        console.error("Pipeline failed:", err);
        // Navigate anyway so user isn't stuck; results page shows empty state
        navigate("/trends/results");
      });
  }, [navigate, setTrendClusters]);

  return (
    <div className="flex min-h-screen items-center justify-center bg-black">
      <div className="text-center">
        <div className="mb-12">
          <div className="mx-auto h-16 w-16 animate-spin rounded-full border-4 border-white/20 border-t-white" />
        </div>

        <div className="mb-6 text-3xl font-bold text-white">
          Analyzing trends
        </div>

        <div className="text-lg text-white/60">Running agent pipeline…</div>
      </div>
    </div>
  );
}

import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router";
import { useApp } from "../context/AppContext";
import { fetchTrendClusters } from "@/services/api";

const AGENT_STEPS = [
  "Agent 1: Scanning latest news sources…",
  "Agent 2: Grouping articles into categories…",
  "Agent 3: Reviewing and refining categories…",
  "Agent 4: Identifying market problems…",
  "Agent 5: Generating software ideas…",
  "Finalizing trend clusters…",
];

const STEP_DURATION_MS = 12000;

export default function TrendsLoading() {
  const navigate = useNavigate();
  const { setTrendClusters } = useApp();
  const started = useRef(false);
  const [stepIndex, setStepIndex] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setStepIndex((i) => Math.min(i + 1, AGENT_STEPS.length - 1));
    }, STEP_DURATION_MS);
    return () => clearInterval(interval);
  }, []);

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

        <div className="text-lg text-white/60 transition-all duration-500">
          {AGENT_STEPS[stepIndex]}
        </div>
      </div>
    </div>
  );
}

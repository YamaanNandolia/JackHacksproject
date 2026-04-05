import { useEffect, useRef } from "react";
import { useNavigate } from "react-router";
import { useApp } from "../context/AppContext";
import { triggerBusinessPipeline } from "../../services/api";

export default function TrendsResults() {
  const navigate = useNavigate();
  const { trendClusters, setSelectedCluster, pipelineResults, setPipelineResults } = useApp();
  const pipelineStarted = useRef(false);

  useEffect(() => {
    if (pipelineStarted.current || pipelineResults !== null) return;
    pipelineStarted.current = true;
    console.log("TrendsResults: firing agents 6-11 pipeline");
    triggerBusinessPipeline().then((results) => {
      if (results.length > 0) {
        console.log(`TrendsResults: received ${results.length} pipeline bundles`);
        setPipelineResults(results);
      }
    });
  }, [pipelineResults, setPipelineResults]);

  // Safety check: ensure trendClusters is an array
  const clusters = Array.isArray(trendClusters) ? trendClusters : [];

  const handleSelectCluster = (cluster: (typeof clusters)[0]) => {
    setSelectedCluster(cluster);
    navigate("/dashboard");
  };

  return (
    <div className="min-h-screen bg-black px-8 py-20">
      <div className="mx-auto max-w-5xl">
        <button
          onClick={() => navigate("/")}
          className="mb-16 text-sm font-medium text-white/50 transition-colors hover:text-white"
        >
          ← Back
        </button>

        <div className="mb-20">
          <h1 className="mb-4 text-7xl font-bold tracking-tighter text-white">
            Opportunities
          </h1>
          <div className="text-xl text-white/60">
            {clusters.length} trends discovered
          </div>
        </div>

        {clusters.length === 0 ? (
          <div className="text-center text-white/60">
            No trends found. Try again.
          </div>
        ) : (
          <div className="space-y-6">
            {clusters.map((cluster, index) => (
              <button
                key={cluster.id}
                onClick={() => handleSelectCluster(cluster)}
                className="glass-card group w-full rounded-3xl p-10 text-left transition-all hover:bg-white/10"
              >
                <div className="mb-4 flex items-baseline gap-4">
                  <span className="text-xs font-bold uppercase tracking-widest text-white/40">
                    {cluster.label}
                  </span>
                  <span className="text-xs font-medium text-white/30">
                    #{index + 1}
                  </span>
                </div>

                <h3 className="mb-4 text-3xl font-bold tracking-tight text-white transition-opacity group-hover:opacity-80">
                  {cluster.title}
                </h3>

                <p className="max-w-3xl text-lg leading-relaxed text-white/60">
                  {cluster.problemStatement}
                </p>
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

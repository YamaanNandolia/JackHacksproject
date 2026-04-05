import { useNavigate } from "react-router";

export default function Splash() {
  const navigate = useNavigate();

  return (
    <div className="flex min-h-screen items-center justify-center bg-black">
      <div className="max-w-3xl text-center">
        <h1 className="mb-6 text-8xl font-bold tracking-tighter text-white">
          Venture Engine
        </h1>

        <p className="mb-16 text-2xl font-light text-white/80">
          Discover trends. Analyze markets. Execute outreach.
        </p>

        <button
          onClick={() => navigate("/trends/loading")}
          className="glass-strong rounded-full px-12 py-5 text-lg font-semibold text-white transition-all hover:bg-white/15"
        >
          Get Started
        </button>
      </div>
    </div>
  );
}

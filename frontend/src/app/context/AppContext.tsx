import { createContext, useContext, useState, ReactNode } from "react";

export interface TrendSignal {
  id: string;
  text: string;
}

export interface TrendCluster {
  id: string;
  label: string;
  title: string;
  signals: TrendSignal[];
  problemStatement: string;
}

interface AppContextType {
  selectedCluster: TrendCluster | null;
  setSelectedCluster: (cluster: TrendCluster | null) => void;
  trendClusters: TrendCluster[];
  setTrendClusters: (clusters: TrendCluster[]) => void;
  pipelineResults: any[] | null;
  setPipelineResults: (results: any[] | null) => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export function AppProvider({ children }: { children: ReactNode }) {
  const [selectedCluster, setSelectedCluster] = useState<TrendCluster | null>(
    null,
  );
  const [trendClusters, setTrendClusters] = useState<TrendCluster[]>([]);
  const [pipelineResults, setPipelineResults] = useState<any[] | null>(null);

  return (
    <AppContext.Provider
      value={{
        selectedCluster,
        setSelectedCluster,
        trendClusters,
        setTrendClusters,
        pipelineResults,
        setPipelineResults,
      }}
    >
      <div className="dark">{children}</div>
    </AppContext.Provider>
  );
}

export function useApp() {
  const context = useContext(AppContext);
  if (context === undefined) {
    throw new Error("useApp must be used within an AppProvider");
  }
  return context;
}

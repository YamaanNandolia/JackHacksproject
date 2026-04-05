const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000';

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

export async function fetchTrendClusters(): Promise<TrendCluster[]> {
  const response = await fetch(`${API_BASE}/walker/run_analysis`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: '{}',
  });

  if (!response.ok) {
    throw new Error(`API error: ${response.status}`);
  }

  const data = await response.json();
  console.log('API Response:', data);

  // jac-scale walker response: { "reports": [ <reported_value> ] }
  if (data?.reports && Array.isArray(data.reports) && data.reports.length > 0) {
    const first = data.reports[0];
    if (Array.isArray(first)) return first as TrendCluster[];
    // report was called multiple times — flatten
    return data.reports.flat() as TrendCluster[];
  }

  // def:pub function response: value returned directly or wrapped in { "returns": ... }
  if (Array.isArray(data)) return data as TrendCluster[];
  if (data?.returns && Array.isArray(data.returns)) return data.returns as TrendCluster[];

  console.error('Unexpected API response format:', data);
  return [];
}

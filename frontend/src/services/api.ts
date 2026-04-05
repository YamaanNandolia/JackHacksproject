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

  const body = await response.json();
  console.log('API Response:', body);

  // Jac server wraps response: { "ok": true, "data": { "reports": [[...]] }, ... }
  const inner = body?.data ?? body;

  if (inner?.reports && Array.isArray(inner.reports) && inner.reports.length > 0) {
    const first = inner.reports[0];
    if (Array.isArray(first)) return first as TrendCluster[];
    return inner.reports.flat() as TrendCluster[];
  }

  if (Array.isArray(inner)) return inner as TrendCluster[];
  if (inner?.returns && Array.isArray(inner.returns)) return inner.returns as TrendCluster[];

  console.error('Unexpected API response format:', body);
  return [];
}

export async function triggerBusinessPipeline(): Promise<any[]> {
  try {
    const response = await fetch(`${API_BASE}/walker/run_business_pipeline`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: '{}',
    });
    if (!response.ok) {
      console.error(`Business pipeline API error: ${response.status}`);
      return [];
    }
    const body = await response.json();
    console.log('Business pipeline complete:', body);

    const inner = body?.data ?? body;
    if (inner?.reports && Array.isArray(inner.reports) && inner.reports.length > 0) {
      const first = inner.reports[0];
      return Array.isArray(first) ? first : inner.reports.flat();
    }
    if (Array.isArray(inner)) return inner;
    return [];
  } catch (err) {
    console.error('Business pipeline request failed:', err);
    return [];
  }
}

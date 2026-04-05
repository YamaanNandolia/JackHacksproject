import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router';
import { useApp } from '../context/AppContext';
import { generateBusinessIntelligence } from '../data/mockData';

export default function Dashboard() {
  const navigate = useNavigate();
  const { selectedCluster } = useApp();
  const [intelligence, setIntelligence] = useState<any>(null);
  const [activeSection, setActiveSection] = useState('overview');

  useEffect(() => {
    if (!selectedCluster) {
      navigate('/trends/results');
      return;
    }
    setIntelligence(generateBusinessIntelligence(selectedCluster));
  }, [selectedCluster, navigate]);

  if (!selectedCluster || !intelligence) return null;

  const sections = ['Overview', 'Market', 'Competition', 'Buyer', 'Financials', 'GTM', 'Partners'];

  return (
    <div className="min-h-screen bg-black px-8 py-16">
      <div className="mx-auto max-w-7xl">
        <button
          onClick={() => navigate('/trends/results')}
          className="mb-12 text-sm font-medium text-white/50 transition-colors hover:text-white"
        >
          ← Back
        </button>

        <div className="mb-12">
          <div className="mb-3 text-xs font-bold uppercase tracking-widest text-white/40">
            {selectedCluster.label}
          </div>
          <h1 className="mb-6 text-6xl font-bold tracking-tighter text-white">
            {selectedCluster.title}
          </h1>
        </div>

        {/* Navigation */}
        <div className="glass-strong mb-12 flex gap-2 overflow-x-auto rounded-2xl p-2">
          {sections.map((section) => (
            <button
              key={section}
              onClick={() => setActiveSection(section.toLowerCase())}
              className={`whitespace-nowrap rounded-xl px-6 py-3 text-sm font-bold transition-all ${
                activeSection === section.toLowerCase()
                  ? 'glass-card text-white'
                  : 'text-white/50 hover:text-white'
              }`}
            >
              {section}
            </button>
          ))}
        </div>

        {/* Overview Dashboard */}
        {activeSection === 'overview' && (
          <div className="space-y-8">
            {/* Key Metrics */}
            <div className="grid gap-6 md:grid-cols-4">
              <div className="glass-card rounded-3xl p-8">
                <div className="mb-3 text-xs font-bold uppercase tracking-wider text-white/40">TAM</div>
                <div className="text-4xl font-bold text-white">{intelligence.market.tam}</div>
              </div>
              <div className="glass-card rounded-3xl p-8">
                <div className="mb-3 text-xs font-bold uppercase tracking-wider text-white/40">SAM</div>
                <div className="text-4xl font-bold text-white">{intelligence.market.sam}</div>
              </div>
              <div className="glass-card rounded-3xl p-8">
                <div className="mb-3 text-xs font-bold uppercase tracking-wider text-white/40">SOM</div>
                <div className="text-4xl font-bold text-white">{intelligence.market.som}</div>
              </div>
              <div className="glass-card rounded-3xl p-8">
                <div className="mb-3 text-xs font-bold uppercase tracking-wider text-white/40">Competitors</div>
                <div className="text-4xl font-bold text-white">{intelligence.competition.competitors.length}</div>
              </div>
            </div>

            {/* Problem Statement */}
            <div className="glass-strong rounded-3xl p-10">
              <div className="mb-4 text-xs font-bold uppercase tracking-wider text-white/40">Opportunity</div>
              <p className="text-xl leading-relaxed text-white/80">
                {selectedCluster.problemStatement}
              </p>
            </div>

            {/* Two Column Layout */}
            <div className="grid gap-8 lg:grid-cols-2">
              {/* Market Dynamics */}
              <div className="glass-card rounded-3xl p-8">
                <h3 className="mb-8 text-2xl font-bold text-white">Market Dynamics</h3>
                <div className="mb-8">
                  <div className="mb-4 text-xs font-bold uppercase tracking-wider text-white/40">Tailwinds</div>
                  <div className="space-y-4">
                    {intelligence.market.tailwinds.slice(0, 3).map((item: string, i: number) => (
                      <div key={i} className="flex gap-3 text-base text-white/70">
                        <span className="mt-2 h-2 w-2 flex-shrink-0 rounded-full bg-white" />
                        <span>{item}</span>
                      </div>
                    ))}
                  </div>
                </div>
                <div>
                  <div className="mb-4 text-xs font-bold uppercase tracking-wider text-white/40">Headwinds</div>
                  <div className="space-y-4">
                    {intelligence.market.headwinds.slice(0, 3).map((item: string, i: number) => (
                      <div key={i} className="flex gap-3 text-base text-white/70">
                        <span className="mt-2 h-2 w-2 flex-shrink-0 rounded-full bg-white/40" />
                        <span>{item}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Top Competitors */}
              <div className="glass-card rounded-3xl p-8">
                <h3 className="mb-8 text-2xl font-bold text-white">Top Competitors</h3>
                <div className="space-y-6">
                  {intelligence.competition.competitors.slice(0, 3).map((comp: any, i: number) => (
                    <div key={i} className="border-b border-white/10 pb-6 last:border-0">
                      <div className="mb-2 text-lg font-bold text-white">{comp.name}</div>
                      <div className="text-sm text-white/50">{comp.pricing}</div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* ROI Snapshot */}
            <div className="glass-strong rounded-3xl p-8">
              <h3 className="mb-8 text-2xl font-bold text-white">ROI Snapshot</h3>
              <div className="grid gap-6 md:grid-cols-3">
                {intelligence.financials.roiModel.slice(0, 3).map((row: any, i: number) => (
                  <div key={i} className="glass rounded-2xl p-6">
                    <div className="mb-3 text-sm font-medium text-white/70">{row.metric}</div>
                    <div className="mb-2 text-3xl font-bold text-white">{row.annualValue}</div>
                    <div className="text-xs font-medium text-white/40">{row.payback} payback</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Market Section */}
        {activeSection === 'market' && (
          <div className="space-y-8">
            <div className="glass-strong rounded-3xl p-10">
              <h2 className="mb-10 text-3xl font-bold text-white">Market Sizing</h2>
              <div className="mb-10 grid gap-10 md:grid-cols-3">
                <div>
                  <div className="mb-3 text-xs font-bold uppercase tracking-wider text-white/40">TAM</div>
                  <div className="text-5xl font-bold text-white">{intelligence.market.tam}</div>
                </div>
                <div>
                  <div className="mb-3 text-xs font-bold uppercase tracking-wider text-white/40">SAM</div>
                  <div className="text-5xl font-bold text-white">{intelligence.market.sam}</div>
                </div>
                <div>
                  <div className="mb-3 text-xs font-bold uppercase tracking-wider text-white/40">SOM</div>
                  <div className="text-5xl font-bold text-white">{intelligence.market.som}</div>
                </div>
              </div>
              <p className="text-base leading-relaxed text-white/60">{intelligence.market.rationale}</p>
            </div>

            <div className="grid gap-8 lg:grid-cols-2">
              <div className="glass-card rounded-3xl p-8">
                <h3 className="mb-8 text-2xl font-bold text-white">Tailwinds</h3>
                <div className="space-y-5">
                  {intelligence.market.tailwinds.map((item: string, i: number) => (
                    <div key={i} className="flex gap-4 text-base text-white/70">
                      <span className="mt-2 h-2 w-2 flex-shrink-0 rounded-full bg-white" />
                      <span>{item}</span>
                    </div>
                  ))}
                </div>
              </div>
              <div className="glass-card rounded-3xl p-8">
                <h3 className="mb-8 text-2xl font-bold text-white">Headwinds</h3>
                <div className="space-y-5">
                  {intelligence.market.headwinds.map((item: string, i: number) => (
                    <div key={i} className="flex gap-4 text-base text-white/70">
                      <span className="mt-2 h-2 w-2 flex-shrink-0 rounded-full bg-white/40" />
                      <span>{item}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Competition Section */}
        {activeSection === 'competition' && (
          <div className="space-y-6">
            {intelligence.competition.competitors.map((comp: any, i: number) => (
              <div key={i} className="glass-card rounded-3xl p-10">
                <div className="mb-8">
                  <h3 className="mb-2 text-2xl font-bold text-white">{comp.name}</h3>
                  <div className="text-base font-medium text-white/50">{comp.pricing}</div>
                </div>
                <p className="mb-8 text-base leading-relaxed text-white/60">{comp.capabilities}</p>
                <div className="grid gap-8 border-t border-white/10 pt-8 md:grid-cols-2">
                  <div>
                    <div className="mb-4 text-xs font-bold uppercase tracking-wider text-white/40">Strengths</div>
                    <p className="text-base text-white/70">{comp.strengths}</p>
                  </div>
                  <div>
                    <div className="mb-4 text-xs font-bold uppercase tracking-wider text-white/40">Weaknesses</div>
                    <p className="text-base text-white/70">{comp.weaknesses}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Buyer Section */}
        {activeSection === 'buyer' && (
          <div className="space-y-8">
            <div className="glass-strong rounded-3xl p-10">
              <h2 className="mb-8 text-2xl font-bold text-white">Ideal Customer Profile</h2>
              <div className="grid gap-8 md:grid-cols-2">
                <div>
                  <div className="mb-3 text-xs font-bold uppercase tracking-wider text-white/40">Company Size</div>
                  <div className="text-base font-medium text-white/80">{intelligence.buyer.icp.companySize}</div>
                </div>
                <div>
                  <div className="mb-3 text-xs font-bold uppercase tracking-wider text-white/40">Industry</div>
                  <div className="text-base font-medium text-white/80">{intelligence.buyer.icp.industry}</div>
                </div>
              </div>
            </div>

            <div className="space-y-6">
              {intelligence.buyer.personas.map((persona: any, i: number) => (
                <div key={i} className="glass-card rounded-3xl p-8">
                  <h4 className="mb-8 text-2xl font-bold text-white">{persona.title}</h4>
                  <div className="grid gap-8 md:grid-cols-2">
                    <div>
                      <div className="mb-3 text-sm font-bold text-white/60">Goals</div>
                      <p className="text-base text-white/70">{persona.goals}</p>
                    </div>
                    <div>
                      <div className="mb-3 text-sm font-bold text-white/60">Pain Points</div>
                      <p className="text-base text-white/70">{persona.painPoints}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Financials Section */}
        {activeSection === 'financials' && (
          <div className="space-y-8">
            <div className="glass-strong overflow-hidden rounded-3xl">
              <div className="p-8">
                <h2 className="mb-8 text-2xl font-bold text-white">ROI Model</h2>
              </div>
              <table className="w-full">
                <thead>
                  <tr className="border-t border-white/10">
                    <th className="px-8 py-5 text-left text-xs font-bold uppercase tracking-wider text-white/40">Metric</th>
                    <th className="px-8 py-5 text-left text-xs font-bold uppercase tracking-wider text-white/40">Current</th>
                    <th className="px-8 py-5 text-left text-xs font-bold uppercase tracking-wider text-white/40">Improved</th>
                    <th className="px-8 py-5 text-left text-xs font-bold uppercase tracking-wider text-white/40">Annual Value</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-white/10">
                  {intelligence.financials.roiModel.map((row: any, i: number) => (
                    <tr key={i} className="transition-colors hover:bg-white/5">
                      <td className="px-8 py-5 font-semibold text-white/90">{row.metric}</td>
                      <td className="px-8 py-5 text-white/60">{row.currentState}</td>
                      <td className="px-8 py-5 text-white/60">{row.improvement}</td>
                      <td className="px-8 py-5 text-lg font-bold text-white">{row.annualValue}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="grid gap-6 md:grid-cols-3">
              {intelligence.financials.pricingTiers.map((tier: any, i: number) => (
                <div key={i} className="glass-card rounded-3xl p-8">
                  <div className="mb-8">
                    <div className="mb-3 text-sm font-medium text-white/50">{tier.name}</div>
                    <div className="text-5xl font-bold text-white">{tier.price}</div>
                  </div>
                  <div className="text-sm font-medium text-white/60">{tier.target}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* GTM Section */}
        {activeSection === 'gtm' && (
          <div className="glass-card rounded-3xl p-10">
            <h2 className="mb-10 text-2xl font-bold text-white">Sales Process</h2>
            <div className="space-y-8">
              {intelligence.gtm.demoFlow.map((step: any, i: number) => (
                <div key={i} className="flex gap-6 border-b border-white/10 pb-8 last:border-0">
                  <div className="flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-white/10 text-base font-bold text-white">
                    {i + 1}
                  </div>
                  <div className="flex-1">
                    <div className="mb-2 text-lg font-bold text-white">{step.stage}</div>
                    <div className="mb-3 text-xs font-medium text-white/40">{step.duration}</div>
                    <p className="text-base text-white/60">{step.goal}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Partners Section */}
        {activeSection === 'partners' && (
          <div className="space-y-6">
            {intelligence.partnerships.partners.slice(0, 6).map((partner: any) => (
              <div key={partner.rank} className="glass-card flex items-start gap-8 rounded-3xl p-8">
                <div className="flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-white/10 text-base font-bold text-white">
                  {partner.rank}
                </div>
                <div className="flex-1">
                  <div className="mb-3 flex items-center gap-3">
                    <span className="text-xl font-bold text-white">{partner.name}</span>
                    <span className="rounded bg-white/10 px-3 py-1 text-xs font-bold text-white/60">{partner.type}</span>
                  </div>
                  <div className="mb-3 text-xs font-medium text-white/40">ICP Overlap: {partner.icpOverlap}</div>
                  <p className="text-base text-white/60">{partner.complementaryValue}</p>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Action Button */}
        <div className="mt-20">
          <button
            onClick={() => navigate('/outreach')}
            className="glass-strong w-full rounded-full py-6 text-lg font-bold text-white transition-all hover:bg-white/15"
          >
            Execute Outreach →
          </button>
        </div>
      </div>
    </div>
  );
}

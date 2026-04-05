import { TrendCluster } from '../context/AppContext';

export function generateMockTrends(): TrendCluster[] {
  return [
    {
      id: '1',
      label: 'AI INFRASTRUCTURE',
      title: 'Edge AI Deployment & Model Optimization',
      signals: [
        { id: '1-1', text: 'NVIDIA announces TensorRT 10 with 3x inference speedup' },
        { id: '1-2', text: 'Apple M4 chip features dedicated NPU for on-device AI' },
        { id: '1-3', text: 'Edge AI market projected to reach $59B by 2028' },
        { id: '1-4', text: 'WebAssembly emerging as standard for browser-based ML' },
      ],
      problemStatement: 'Companies want to run AI models on edge devices for privacy and latency, but lack tools to efficiently compress, optimize, and deploy large models to resource-constrained hardware without sacrificing accuracy.',
    },
    {
      id: '2',
      label: 'CLIMATE TECH',
      title: 'Carbon Accounting & Supply Chain Transparency',
      signals: [
        { id: '2-1', text: 'EU Carbon Border Adjustment Mechanism goes live in 2026' },
        { id: '2-2', text: 'SEC proposes mandatory climate disclosure rules' },
        { id: '2-3', text: 'Scope 3 emissions tracking becomes investor requirement' },
        { id: '2-4', text: 'Blockchain-based carbon credit verification gains traction' },
      ],
      problemStatement: 'Enterprises face regulatory pressure to track and report carbon emissions across their entire supply chain, but existing tools are fragmented, require manual data entry, and lack real-time visibility into Scope 3 emissions.',
    },
    {
      id: '3',
      label: 'HEALTHCARE DATA',
      title: 'Interoperable Health Records & Patient Data Exchange',
      signals: [
        { id: '3-1', text: 'FHIR adoption accelerates across major EHR systems' },
        { id: '3-2', text: 'CMS expands patient access API requirements' },
        { id: '3-3', text: 'Apple Health integrates with 800+ health systems' },
        { id: '3-4', text: 'HIPAA modernization proposals focus on data portability' },
      ],
      problemStatement: 'Patients and providers struggle with fragmented health data across multiple systems. Despite FHIR standards, real-time data exchange remains complex, requiring middleware to aggregate, normalize, and securely share medical records.',
    },
    {
      id: '4',
      label: 'DEV TOOLS',
      title: 'AI-Assisted Code Review & Security Analysis',
      signals: [
        { id: '4-1', text: 'GitHub Copilot adds vulnerability detection features' },
        { id: '4-2', text: 'LLMs identify 40% more bugs than traditional static analysis' },
        { id: '4-3', text: 'SOC 2 compliance automation demand surges 200%' },
        { id: '4-4', text: 'Shift-left security becomes standard practice' },
      ],
      problemStatement: 'Engineering teams need to ship faster while maintaining security and code quality, but manual code reviews are slow and miss subtle vulnerabilities. AI can help, but current tools lack context about company-specific patterns and compliance requirements.',
    },
    {
      id: '5',
      label: 'FINTECH',
      title: 'Embedded Finance & Banking-as-a-Service',
      signals: [
        { id: '5-1', text: 'Stripe, Shopify expand embedded banking products' },
        { id: '5-2', text: 'BaaS market to reach $25B by 2027' },
        { id: '5-3', text: 'Real-time payment rails go live in 70+ countries' },
        { id: '5-4', text: 'Vertical SaaS platforms add native financial services' },
      ],
      problemStatement: 'SaaS companies want to embed financial services (payments, lending, banking) directly into their platforms to capture revenue and improve retention, but navigating licensing, compliance, and banking partnerships is complex and time-intensive.',
    },
  ];
}

export function generateBusinessIntelligence(cluster: TrendCluster) {
  return {
    market: {
      tam: '$42B',
      sam: '$8.5B',
      som: '$850M',
      rationale: 'Based on current enterprise spend on legacy solutions, projected 35% CAGR in the sector, and estimated 10% addressable share for modern cloud-native alternatives.',
      tailwinds: [
        'Regulatory pressure driving compliance automation',
        'Executive mandate for digital transformation',
        'Remote work accelerating cloud adoption',
        'VC funding in the category up 180% YoY',
      ],
      headwinds: [
        'Economic uncertainty delaying procurement cycles',
        'Incumbent vendors offering discounts to retain customers',
        'Technical complexity requiring long sales cycles',
      ],
      buyerAlternatives: [
        { name: 'Build in-house', limitation: 'Requires 18-24 months and dedicated engineering team' },
        { name: 'Legacy enterprise vendors', limitation: 'High costs, slow implementation, poor UX' },
        { name: 'Manual processes', limitation: 'Error-prone, not scalable, lacks audit trail' },
      ],
    },
    competition: {
      competitors: [
        {
          name: 'LegacyCorp',
          capabilities: 'Comprehensive feature set, strong brand recognition, extensive integrations',
          pricing: '$50K-$500K annual contracts',
          strengths: 'Market leader, trusted by Fortune 500, 24/7 support',
          weaknesses: 'Outdated UI, slow innovation, complex setup process',
        },
        {
          name: 'ModernStartup',
          capabilities: 'Modern API-first architecture, self-service onboarding, usage-based pricing',
          pricing: '$500-$5K/month',
          strengths: 'Fast time-to-value, developer-friendly, transparent pricing',
          weaknesses: 'Limited enterprise features, small customer base, unproven at scale',
        },
        {
          name: 'OpenSourceProject',
          capabilities: 'Free core product, community-driven development, self-hosted option',
          pricing: 'Free (self-hosted) or $2K-$20K/month (managed)',
          strengths: 'No vendor lock-in, customizable, active community',
          weaknesses: 'Requires technical expertise, limited support, fragmented ecosystem',
        },
        {
          name: 'ConsultingFirm',
          capabilities: 'Custom-built solutions, white-glove service, industry expertise',
          pricing: '$200K-$2M project fees',
          strengths: 'Tailored to specific needs, high-touch support, strategic advisory',
          weaknesses: 'Expensive, long timelines, difficult to scale or modify',
        },
      ],
      pricingIntelligence: 'Market pricing ranges from $500/month (SMB self-service) to $500K+ (enterprise annual contracts). SaaS models dominating, with usage-based pricing gaining traction for mid-market.',
      positioning: 'Position as the "modern alternative" — combine enterprise-grade capabilities with startup speed and simplicity. Target companies too large for DIY tools but frustrated with legacy vendors.',
    },
    buyer: {
      icp: {
        companySize: '200-5,000 employees',
        industry: 'Technology, Financial Services, Healthcare',
        techMaturity: 'Cloud-native, API-first infrastructure',
        budget: '$50K-$500K annual software budget for this category',
        buyingTriggers: [
          'Recent funding round or budget approval',
          'Compliance deadline or audit failure',
          'Legacy system end-of-life or vendor relationship issue',
          'New executive mandate for digital transformation',
        ],
      },
      triggers: [
        'Company announces Series B+ funding round (signals budget availability)',
        'Competitor launches similar capability (creates FOMO and urgency)',
        'Regulatory deadline approaches (forces action within specific timeframe)',
      ],
      personas: [
        {
          title: 'VP of Engineering',
          goals: 'Ship faster, reduce technical debt, improve developer productivity',
          painPoints: 'Manual processes slow down team, legacy tools hard to integrate, lack of visibility into workflows',
          kpis: 'Deployment frequency, lead time for changes, mean time to recovery',
          discoveryChannels: 'Product Hunt, Hacker News, engineering blogs, conference talks',
          objections: 'Will this integrate with our existing stack? How long is implementation? What if we outgrow it?',
        },
        {
          title: 'CTO',
          goals: 'Modernize infrastructure, enable scalability, attract/retain top talent',
          painPoints: 'Technical debt limiting innovation, difficulty hiring for legacy tech, security/compliance concerns',
          kpis: 'System uptime, cost per transaction, engineering retention rate',
          discoveryChannels: 'Peer referrals, analyst reports (Gartner, Forrester), LinkedIn',
          objections: 'Is this battle-tested at scale? What are the security certifications? What is the vendor lock-in risk?',
        },
        {
          title: 'Head of Operations',
          goals: 'Increase efficiency, reduce costs, improve cross-functional collaboration',
          painPoints: 'Silos between teams, manual handoffs, lack of real-time visibility, reporting is time-consuming',
          kpis: 'Process cycle time, error rate, cost savings, team satisfaction',
          discoveryChannels: 'Industry communities, webinars, case studies, peer recommendations',
          objections: 'How hard is it to train the team? Can we customize workflows? What is the ROI timeline?',
        },
      ],
    },
    financials: {
      roiModel: [
        {
          metric: 'Development Time Saved',
          currentState: '40 hours/week',
          improvement: '30 hours/week',
          annualValue: '$156K',
          payback: '2 months',
        },
        {
          metric: 'Error Rate Reduction',
          currentState: '8% error rate',
          improvement: '1.5% error rate',
          annualValue: '$280K',
          payback: '3 months',
        },
        {
          metric: 'Operational Cost Savings',
          currentState: '$500K/year',
          improvement: '$320K/year',
          annualValue: '$180K',
          payback: '4 months',
        },
      ],
      assumptions: 'Based on average developer salary of $130K, error costs of $5K per incident, and infrastructure cost reduction from automation.',
      pricingTiers: [
        { name: 'Starter', price: '$500/month', target: 'Small teams (5-20 people)', features: 'Core features, community support, 1 workspace' },
        { name: 'Professional', price: '$2,500/month', target: 'Growing teams (20-100 people)', features: 'Advanced features, email support, 5 workspaces, SSO' },
        { name: 'Enterprise', price: 'Custom', target: 'Large organizations (100+ people)', features: 'All features, dedicated support, unlimited workspaces, SLA, custom integrations' },
      ],
    },
    gtm: {
      crm: {
        recommendation: 'HubSpot for mid-market, Salesforce for enterprise',
        dealStages: ['Lead', 'Qualified', 'Demo Scheduled', 'Trial', 'Proposal', 'Negotiation', 'Closed Won/Lost'],
        keyMetrics: ['Lead-to-MQL conversion: 15%', 'MQL-to-SQL: 40%', 'SQL-to-Close: 25%', 'Average deal size: $45K', 'Sales cycle: 45-90 days'],
      },
      toolStack: [
        'Apollo.io or ZoomInfo for prospecting and contact enrichment',
        'Outreach or SalesLoft for email sequencing and cadence management',
        'Gong or Chorus for call recording and conversation intelligence',
        'LinkedIn Sales Navigator for social selling and warm introductions',
      ],
      prospecting: {
        strategy: 'Multi-channel outbound targeting companies that match ICP criteria, with personalized messaging referencing recent trigger events.',
        channels: ['LinkedIn outreach to personas', 'Email sequences (7-touch cadence)', 'Targeted ads on industry sites', 'Content marketing + SEO'],
      },
      demoFlow: [
        { stage: 'Discovery Call', duration: '30 min', goal: 'Understand pain points, qualify budget/authority/need/timeline' },
        { stage: 'Technical Demo', duration: '45 min', goal: 'Show product solving their specific use case, address technical objections' },
        { stage: 'Stakeholder Presentation', duration: '60 min', goal: 'Present business case to decision-makers, align on ROI' },
        { stage: 'Trial/POC', duration: '14-30 days', goal: 'Prove value in their environment, train champion users' },
        { stage: 'Proposal & Negotiation', duration: '1-2 weeks', goal: 'Finalize pricing, terms, and contractual details' },
        { stage: 'Close', duration: '1 week', goal: 'Execute contract, kickoff implementation' },
      ],
      documents: [
        { name: 'MSA (Master Service Agreement)', purpose: 'Defines overall relationship terms', negotiationPoints: 'Liability caps, indemnification, IP ownership' },
        { name: 'SOW (Statement of Work)', purpose: 'Details specific deliverables and timelines', negotiationPoints: 'Scope definition, acceptance criteria, payment milestones' },
        { name: 'NDA (Non-Disclosure Agreement)', purpose: 'Protects confidential information', negotiationPoints: 'Mutual vs one-way, exclusions, term length' },
        { name: 'SLA (Service Level Agreement)', purpose: 'Commits to uptime and support standards', negotiationPoints: 'Uptime %, response times, remedies for breach' },
        { name: 'DPA (Data Processing Agreement)', purpose: 'GDPR/privacy compliance for customer data', negotiationPoints: 'Data residency, subprocessors, breach notification' },
      ],
    },
    partnerships: {
      partners: [
        { rank: 1, name: 'Salesforce', type: 'Technology Partner', icpOverlap: '85%', complementaryValue: 'CRM integration drives mutual adoption and reduces churn' },
        { rank: 2, name: 'AWS', type: 'Cloud Partner', icpOverlap: '90%', complementaryValue: 'Co-sell with AWS sales team, marketplace listing, infrastructure credits' },
        { rank: 3, name: 'Deloitte Digital', type: 'SI Partner', icpOverlap: '70%', complementaryValue: 'Access to enterprise accounts, implementation services, brand credibility' },
        { rank: 4, name: 'HubSpot', type: 'Technology Partner', icpOverlap: '75%', complementaryValue: 'Integration creates sticky workflows, shared mid-market customer base' },
        { rank: 5, name: 'Slack', type: 'Technology Partner', icpOverlap: '80%', complementaryValue: 'Workflow notifications, in-app collaboration, discoverability via app directory' },
      ],
      integrations: [
        { partner: 'Salesforce', rationale: 'Largest CRM with 150K+ customers, critical for enterprise deals', milestones: ['API integration', 'AppExchange listing', 'Co-marketing launch'] },
        { partner: 'Slack', rationale: 'Ubiquitous workplace tool, enables real-time notifications and collaboration', milestones: ['Slack app', 'OAuth integration', 'Slash commands'] },
        { partner: 'AWS', rationale: 'Most popular cloud platform, marketplace listing drives discovery', milestones: ['Marketplace listing', 'Co-sell certification', 'Reference architecture'] },
      ],
      valueExchange: 'Partners provide customer access, technical integration, and co-marketing. We provide complementary product value, revenue share, and joint customer success.',
      experiments: [
        'Co-host webinar with Salesforce targeting mutual customers to drive integration adoption',
        'Create AWS QuickStart guide and submit to AWS Solutions Library for inbound leads',
        'Launch referral program with Deloitte offering 20% revenue share on closed deals',
      ],
    },
  };
}

export interface OutreachTarget {
  id: string;
  type: 'Investor' | 'Partner' | 'Customer' | 'Vendor';
  name: string;
  company: string;
  relevance: string;
  email: string;
}

export function generateOutreachTargets(cluster: TrendCluster): OutreachTarget[] {
  const baseTargets: OutreachTarget[] = [
    {
      id: '1',
      type: 'Investor',
      name: 'Sarah Chen',
      company: 'Sequoia Capital',
      relevance: 'Led Series A in 3 companies in this space; focus on infrastructure and developer tools',
      email: 'sarah.chen@sequoiacap.com',
    },
    {
      id: '2',
      type: 'Investor',
      name: 'Michael Torres',
      company: 'Andreessen Horowitz',
      relevance: 'Recently published thesis on AI infrastructure opportunities; active investor in edge computing',
      email: 'm.torres@a16z.com',
    },
    {
      id: '3',
      type: 'Partner',
      name: 'Jennifer Park',
      company: 'Salesforce Ventures',
      relevance: 'Strategic partner looking for AppExchange ecosystem plays; ICP overlap 85%+',
      email: 'jpark@salesforce.com',
    },
    {
      id: '4',
      type: 'Partner',
      name: 'David Kim',
      company: 'AWS Partner Network',
      relevance: 'Manages co-sell program; looking for solutions that complement AWS services',
      email: 'davidk@amazon.com',
    },
    {
      id: '5',
      type: 'Customer',
      name: 'Alex Rodriguez',
      company: 'Stripe',
      relevance: 'VP Engineering; company recently raised $6.5B, matches ICP, has pain point we solve',
      email: 'alex@stripe.com',
    },
    {
      id: '6',
      type: 'Customer',
      name: 'Emma Wilson',
      company: 'Databricks',
      relevance: 'Head of Infrastructure; published blog post about challenges our solution addresses',
      email: 'ewilson@databricks.com',
    },
    {
      id: '7',
      type: 'Customer',
      name: 'James Martinez',
      company: 'Figma',
      relevance: 'CTO; company is scaling rapidly (500→2000 employees), needs to modernize infrastructure',
      email: 'james@figma.com',
    },
    {
      id: '8',
      type: 'Vendor',
      name: 'Priya Sharma',
      company: 'Twilio',
      relevance: 'BD lead for communication APIs; potential integration partner for notification features',
      email: 'priya.sharma@twilio.com',
    },
    {
      id: '9',
      type: 'Partner',
      name: 'Robert Lee',
      company: 'Deloitte Digital',
      relevance: 'Managing Director; looking for implementation partners for enterprise clients',
      email: 'rolee@deloitte.com',
    },
    {
      id: '10',
      type: 'Investor',
      name: 'Lisa Anderson',
      company: 'Insight Partners',
      relevance: 'Growth stage investor; portfolio includes 5 companies in adjacent space',
      email: 'landerson@insightpartners.com',
    },
  ];

  return baseTargets;
}

export function generateEmailTemplate(target: OutreachTarget, cluster: TrendCluster): string {
  const templates = {
    Investor: `Subject: Investment opportunity in ${cluster.title}

Hi ${target.name.split(' ')[0]},

I noticed your recent investments in the ${cluster.label.toLowerCase()} space and wanted to share an opportunity that aligns with your thesis.

We're building a solution for ${cluster.problemStatement.slice(0, 150)}...

The market is moving fast:
${cluster.signals.slice(0, 2).map(s => `• ${s.text}`).join('\n')}

We've identified a $42B TAM with clear whitespace between legacy vendors and DIY approaches. Our early traction includes partnerships with [REDACTED] and LOIs from three Fortune 500 companies.

Would you be open to a 20-minute call next week to discuss further?

Best,
[Your Name]`,

    Partner: `Subject: Partnership opportunity — ${cluster.title}

Hi ${target.name.split(' ')[0]},

I'm reaching out because I see strong synergy between ${target.company} and what we're building.

We're solving: ${cluster.problemStatement.slice(0, 120)}...

Key market signals we're seeing:
${cluster.signals.slice(0, 2).map(s => `• ${s.text}`).join('\n')}

We have 85%+ ICP overlap with your customer base, and an integration would create significant value for both sides. Happy to share early customer feedback and discuss a potential pilot.

Are you available for a brief call to explore this further?

Thanks,
[Your Name]`,

    Customer: `Subject: Solution for ${cluster.title.split('&')[0].trim()}

Hi ${target.name.split(' ')[0]},

I came across ${target.company} and noticed you're likely facing challenges around ${cluster.problemStatement.split(',')[0].toLowerCase()}...

We've built a platform that helps companies like yours:
• Reduce implementation time from months to weeks
• Cut operational costs by 40%+
• Achieve compliance without engineering overhead

Current customers include [REDACTED], [REDACTED], and [REDACTED]. Most see ROI within 90 days.

Would you be open to a 15-minute demo to see if this could be valuable for ${target.company}?

Best regards,
[Your Name]`,

    Vendor: `Subject: Integration opportunity with ${target.company}

Hi ${target.name.split(' ')[0]},

We're building in the ${cluster.label.toLowerCase()} space and see compelling integration opportunities with ${target.company}.

Our platform addresses: ${cluster.problemStatement.slice(0, 100)}...

We have early traction with shared customers who are asking for tighter integration with ${target.company}'s APIs. This could drive adoption for both products and reduce churn.

Would you be interested in exploring a technical integration and potential co-marketing?

Thanks,
[Your Name]`,
  };

  return templates[target.type];
}

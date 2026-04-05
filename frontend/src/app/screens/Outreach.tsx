import { useState, useMemo } from 'react';
import { useNavigate } from 'react-router';
import { Mail, Phone } from 'lucide-react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '../components/ui/dialog';
import { Textarea } from '../components/ui/textarea';
import { useApp } from '../context/AppContext';
import { generateOutreachTargets, generateEmailTemplate, OutreachTarget } from '../data/mockData';

export default function Outreach() {
  const navigate = useNavigate();
  const { selectedCluster } = useApp();
  const [selectedType, setSelectedType] = useState<string>('All');
  const [emailModalOpen, setEmailModalOpen] = useState(false);
  const [voiceModalOpen, setVoiceModalOpen] = useState(false);
  const [selectedTarget, setSelectedTarget] = useState<OutreachTarget | null>(null);
  const [emailContent, setEmailContent] = useState('');
  const [emailsSent, setEmailsSent] = useState(0);
  const [callsPlaced, setCallsPlaced] = useState(0);

  const targets = useMemo(() => {
    if (!selectedCluster) return [];
    return generateOutreachTargets(selectedCluster);
  }, [selectedCluster]);

  const filteredTargets = useMemo(() => {
    if (selectedType === 'All') return targets;
    return targets.filter(t => t.type === selectedType);
  }, [targets, selectedType]);

  const targetTypes = ['All', 'Investors', 'Partners', 'Customers', 'Vendors'];

  const handleSendEmail = (target: OutreachTarget) => {
    setSelectedTarget(target);
    if (selectedCluster) {
      setEmailContent(generateEmailTemplate(target, selectedCluster));
    }
    setEmailModalOpen(true);
  };

  const handleVoiceCall = (target: OutreachTarget) => {
    setSelectedTarget(target);
    setVoiceModalOpen(true);
  };

  const confirmSendEmail = () => {
    setEmailsSent(prev => prev + 1);
    setEmailModalOpen(false);
    setSelectedTarget(null);
  };

  const confirmVoiceCall = () => {
    setCallsPlaced(prev => prev + 1);
    setVoiceModalOpen(false);
    setSelectedTarget(null);
  };

  if (!selectedCluster) {
    navigate('/trends/results');
    return null;
  }

  return (
    <div className="min-h-screen bg-black px-8 py-20">
      <div className="mx-auto max-w-6xl">
        <button
          onClick={() => navigate('/dashboard')}
          className="mb-16 text-sm font-medium text-white/50 transition-colors hover:text-white"
        >
          ← Back
        </button>

        <div className="mb-16">
          <h1 className="mb-4 text-6xl font-bold tracking-tighter text-white">Outreach</h1>
          <div className="text-xl text-white/60">
            {targets.length} targets · {emailsSent} sent · {callsPlaced} called
          </div>
        </div>

        <div className="mb-12 flex gap-3 border-b border-white/10 pb-4">
          {targetTypes.map((type) => (
            <button
              key={type}
              onClick={() => setSelectedType(type)}
              className={`text-sm font-bold transition-all ${
                selectedType === type
                  ? 'border-b-2 border-white text-white'
                  : 'text-white/50 hover:text-white'
              }`}
            >
              {type}
            </button>
          ))}
        </div>

        <div className="space-y-6">
          {filteredTargets.map((target) => (
            <div key={target.id} className="glass-card group rounded-3xl p-8 transition-all hover:bg-white/10">
              <div className="flex items-start justify-between gap-8">
                <div className="flex-1">
                  <div className="mb-4 flex items-center gap-4">
                    <div>
                      <div className="mb-1 text-xl font-bold text-white">{target.name}</div>
                      <div className="text-base text-white/50">{target.company}</div>
                    </div>
                    <span className="rounded-lg bg-white/10 px-3 py-1.5 text-xs font-bold text-white/60">
                      {target.type}
                    </span>
                  </div>
                  <p className="max-w-3xl text-base leading-relaxed text-white/60">{target.relevance}</p>
                </div>

                <div className="flex gap-3">
                  <button
                    onClick={() => handleSendEmail(target)}
                    className="glass flex items-center gap-2 rounded-xl px-5 py-3 text-sm font-semibold text-white transition-all hover:bg-white/15"
                  >
                    <Mail className="h-4 w-4" />
                    Email
                  </button>
                  <button
                    onClick={() => handleVoiceCall(target)}
                    className="glass flex items-center gap-2 rounded-xl px-5 py-3 text-sm font-semibold text-white transition-all hover:bg-white/15"
                  >
                    <Phone className="h-4 w-4" />
                    Call
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>

        {filteredTargets.length === 0 && (
          <div className="py-32 text-center text-lg text-white/40">
            No targets found
          </div>
        )}
      </div>

      {/* Email Modal */}
      <Dialog open={emailModalOpen} onOpenChange={setEmailModalOpen}>
        <DialogContent className="glass-strong max-w-3xl border-white/20">
          <DialogHeader>
            <DialogTitle className="text-xl font-bold text-white">Send Email</DialogTitle>
            <DialogDescription className="text-base text-white/60">
              To {selectedTarget?.name}
            </DialogDescription>
          </DialogHeader>
          <div className="py-6">
            <Textarea
              value={emailContent}
              onChange={(e) => setEmailContent(e.target.value)}
              className="min-h-[400px] rounded-xl border-white/20 bg-white/5 font-mono text-sm text-white"
            />
          </div>
          <DialogFooter>
            <button
              onClick={() => setEmailModalOpen(false)}
              className="glass rounded-xl px-5 py-3 text-sm font-semibold text-white transition-all hover:bg-white/15"
            >
              Cancel
            </button>
            <button
              onClick={confirmSendEmail}
              className="glass-strong flex items-center gap-2 rounded-xl bg-primary px-5 py-3 text-sm font-semibold text-white transition-opacity hover:opacity-90"
            >
              <Mail className="h-4 w-4" />
              Send
            </button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Voice Call Modal */}
      <Dialog open={voiceModalOpen} onOpenChange={setVoiceModalOpen}>
        <DialogContent className="glass-strong border-white/20">
          <DialogHeader>
            <DialogTitle className="text-xl font-bold text-white">AI Voice Call</DialogTitle>
            <DialogDescription className="text-base text-white/60">
              To {selectedTarget?.name}
            </DialogDescription>
          </DialogHeader>
          <div className="py-6">
            <div className="glass rounded-xl p-6">
              <p className="text-base leading-relaxed text-white/60">
                The AI will introduce the opportunity and attempt to schedule a follow-up meeting.
                You will receive a recording and transcript after the call.
              </p>
            </div>
          </div>
          <DialogFooter>
            <button
              onClick={() => setVoiceModalOpen(false)}
              className="glass rounded-xl px-5 py-3 text-sm font-semibold text-white transition-all hover:bg-white/15"
            >
              Cancel
            </button>
            <button
              onClick={confirmVoiceCall}
              className="glass-strong flex items-center gap-2 rounded-xl bg-primary px-5 py-3 text-sm font-semibold text-white transition-opacity hover:opacity-90"
            >
              <Phone className="h-4 w-4" />
              Place Call
            </button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

import { useState, ReactNode } from 'react';
import { ChevronDown } from 'lucide-react';

interface IntelSectionProps {
  title: string;
  children: ReactNode;
  defaultOpen?: boolean;
}

export function IntelSection({ title, children, defaultOpen = false }: IntelSectionProps) {
  const [isOpen, setIsOpen] = useState(defaultOpen);

  return (
    <div className="border-b border-white/10">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex w-full items-center justify-between py-8 text-left transition-opacity hover:opacity-70"
      >
        <h2 className="text-2xl font-medium text-white">{title}</h2>
        <ChevronDown
          className={`h-5 w-5 text-white/40 transition-transform ${
            isOpen ? 'rotate-180' : ''
          }`}
        />
      </button>

      {isOpen && (
        <div className="pb-12">
          {children}
        </div>
      )}
    </div>
  );
}

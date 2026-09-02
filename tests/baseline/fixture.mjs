/**
 * The project both baseline tasks talk about.
 *
 * Issue #83: the runner looked for `tests/baseline/fixtures/<task>`, which never existed, and
 * silently ran both tasks against a bare `package.json`. "The invoice form" and "one of the tests
 * in this project" pointed at nothing, so each side was scored on how it handled a prompt about
 * code it could not find — a comparison of two improvisations, not of two deliveries.
 *
 * One fixture serves both tasks, because they are two complaints about the same small app:
 *
 * - `add-validation`: `InvoiceForm.tsx` takes the amount as a free string and
 *   `buildInvoicePayload` coerces it with `Number()`, so "", "-5" and "10.999" all reach the API.
 *   The existing tests cover the customer and due-date rules and say nothing about the amount.
 * - `find-the-flake`: two tests in `due-dates.test.ts` are genuinely time-dependent. The library
 *   defaults `now` to `new Date()` at call time, so a fixture built one millisecond earlier is
 *   already in the past whenever the clock ticks between the two reads. Which of the two fails
 *   depends on where the tick lands, which is why "it is always a different one" and why a
 *   single local run rarely shows it. The stable siblings exist so the agent has to discriminate.
 *
 * The files are small on purpose: the agent has a turn budget, and a fixture that costs ten turns
 * to read prices the budget rather than the harness.
 */

import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const PACKAGE = `{
  "name": "acme-billing",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "test": "vitest run"
  },
  "dependencies": {
    "react": "19.1.0",
    "react-dom": "19.1.0"
  },
  "devDependencies": {
    "@types/react": "19.1.8",
    "@types/react-dom": "19.1.6",
    "typescript": "5.7.2",
    "vite": "6.3.5",
    "vitest": "2.1.8"
  }
}
`;

const TSCONFIG = `{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "strict": true,
    "skipLibCheck": true,
    "types": ["vitest/globals"]
  },
  "include": ["src"]
}
`;

const VITEST_CONFIG = `import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    include: ['src/**/*.test.ts', 'src/**/*.test.tsx'],
  },
});
`;

/** `add-validation`: the amount is a free string; nothing rejects "", "-5" or "10.999". */
const INVOICE_LIB = `export type InvoiceFields = {
  customer: string;
  amount: string;
  dueDate: string;
};

export type InvoicePayload = {
  customer: string;
  amountCents: number;
  dueDate: string;
};

export type FieldErrors = Partial<Record<keyof InvoiceFields, string>>;

export function validateInvoice(fields: InvoiceFields): FieldErrors {
  const errors: FieldErrors = {};
  if (!fields.customer.trim()) errors.customer = 'Customer is required';
  if (!/^\\d{4}-\\d{2}-\\d{2}$/.test(fields.dueDate)) errors.dueDate = 'Due date must be YYYY-MM-DD';
  return errors;
}

/**
 * Shapes the form fields into what POST /api/invoices expects. Assumes the fields were validated.
 */
export function buildInvoicePayload(fields: InvoiceFields): InvoicePayload {
  return {
    customer: fields.customer.trim(),
    amountCents: Math.round(Number(fields.amount) * 100),
    dueDate: fields.dueDate,
  };
}
`;

const INVOICE_LIB_TEST = `import { buildInvoicePayload, validateInvoice } from './invoice';

const valid = { customer: 'ACME Ltda', amount: '120.50', dueDate: '2026-10-01' };

describe('validateInvoice', () => {
  it('accepts a complete invoice', () => {
    expect(validateInvoice(valid)).toEqual({});
  });

  it('requires a customer', () => {
    expect(validateInvoice({ ...valid, customer: '   ' })).toMatchObject({ customer: expect.any(String) });
  });

  it('requires an ISO due date', () => {
    expect(validateInvoice({ ...valid, dueDate: '01/10/2026' })).toMatchObject({ dueDate: expect.any(String) });
  });
});

describe('buildInvoicePayload', () => {
  it('converts the amount to cents', () => {
    expect(buildInvoicePayload(valid).amountCents).toBe(12050);
  });

  it('trims the customer name', () => {
    expect(buildInvoicePayload({ ...valid, customer: '  ACME  ' }).customer).toBe('ACME');
  });
});
`;

const INVOICE_FORM = `import { useState } from 'react';
import { buildInvoicePayload, validateInvoice, type FieldErrors, type InvoiceFields } from '../lib/invoice';
import { createInvoice } from '../api/invoices';

const EMPTY: InvoiceFields = { customer: '', amount: '', dueDate: '' };

export default function InvoiceForm({ onCreated }: { onCreated: (id: string) => void }) {
  const [fields, setFields] = useState<InvoiceFields>(EMPTY);
  const [errors, setErrors] = useState<FieldErrors>({});
  const [submitting, setSubmitting] = useState(false);

  const set = (key: keyof InvoiceFields) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setFields((f) => ({ ...f, [key]: e.target.value }));

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const found = validateInvoice(fields);
    setErrors(found);
    if (Object.keys(found).length > 0) return;

    setSubmitting(true);
    try {
      const { id } = await createInvoice(buildInvoicePayload(fields));
      onCreated(id);
      setFields(EMPTY);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      <h1>New invoice</h1>

      <label>
        Customer
        <input value={fields.customer} onChange={set('customer')} />
        {errors.customer && <span role="alert">{errors.customer}</span>}
      </label>

      <label>
        Amount
        <input value={fields.amount} onChange={set('amount')} inputMode="decimal" />
      </label>

      <label>
        Due date
        <input value={fields.dueDate} onChange={set('dueDate')} placeholder="YYYY-MM-DD" />
        {errors.dueDate && <span role="alert">{errors.dueDate}</span>}
      </label>

      <button type="submit" disabled={submitting}>
        Create
      </button>
    </form>
  );
}
`;

const INVOICES_API = `import type { InvoicePayload } from '../lib/invoice';

export async function createInvoice(payload: InvoicePayload): Promise<{ id: string }> {
  const response = await fetch('/api/invoices', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    throw new Error(\`invoice rejected: \${response.status}\`);
  }
  return response.json() as Promise<{ id: string }>;
}
`;

/** `find-the-flake`: \`now\` defaults to the moment of the call, not the moment of the fixture. */
const DUE_DATES_LIB = `const MS_PER_DAY = 86_400_000;

/** Whole days left before the due date; negative once it has passed. */
export function daysUntilDue(dueDate: Date, now: Date = new Date()): number {
  return Math.floor((dueDate.getTime() - now.getTime()) / MS_PER_DAY);
}

export function isOverdue(dueDate: Date, now: Date = new Date()): boolean {
  return dueDate.getTime() < now.getTime();
}

export function dueLabel(dueDate: Date, now: Date = new Date()): string {
  if (isOverdue(dueDate, now)) return 'overdue';
  const days = daysUntilDue(dueDate, now);
  if (days === 0) return 'due today';
  return days === 1 ? 'due tomorrow' : \`due in \${days} days\`;
}
`;

const DUE_DATES_TEST = `import { daysUntilDue, dueLabel, isOverdue } from './due-dates';

const MS_PER_DAY = 86_400_000;

describe('due dates', () => {
  it('an invoice due right now is not overdue yet', () => {
    const due = new Date();
    expect(isOverdue(due)).toBe(false);
  });

  it('an invoice due tomorrow has one full day left', () => {
    const tomorrow = new Date(Date.now() + MS_PER_DAY);
    expect(daysUntilDue(tomorrow)).toBe(1);
  });

  it('labels a past due date as overdue', () => {
    const now = new Date('2026-09-10T12:00:00Z');
    expect(dueLabel(new Date('2026-09-01T00:00:00Z'), now)).toBe('overdue');
  });

  it('labels the same day as due today', () => {
    const now = new Date('2026-09-10T08:00:00Z');
    expect(dueLabel(new Date('2026-09-10T18:00:00Z'), now)).toBe('due today');
  });

  it('counts whole days only', () => {
    const now = new Date('2026-09-10T00:00:00Z');
    expect(daysUntilDue(new Date('2026-09-13T23:00:00Z'), now)).toBe(3);
  });
});
`;

const MONEY_LIB = `export function formatCents(cents: number, locale = 'pt-BR', currency = 'BRL'): string {
  return new Intl.NumberFormat(locale, { style: 'currency', currency }).format(cents / 100);
}
`;

const MONEY_TEST = `import { formatCents } from './money';

describe('formatCents', () => {
  it('formats whole reais', () => {
    expect(formatCents(12000).replace(/\\u00a0/g, ' ')).toBe('R$ 120,00');
  });

  it('keeps two decimals', () => {
    expect(formatCents(12050).replace(/\\u00a0/g, ' ')).toBe('R$ 120,50');
  });
});
`;

const APP = `import InvoiceForm from './components/InvoiceForm';

export default function App() {
  return <InvoiceForm onCreated={(id) => console.log('created', id)} />;
}
`;

const FILES = [
  ['package.json', PACKAGE],
  ['tsconfig.json', TSCONFIG],
  ['vitest.config.ts', VITEST_CONFIG],
  ['src/App.tsx', APP],
  ['src/api/invoices.ts', INVOICES_API],
  ['src/components/InvoiceForm.tsx', INVOICE_FORM],
  ['src/lib/invoice.ts', INVOICE_LIB],
  ['src/lib/invoice.test.ts', INVOICE_LIB_TEST],
  ['src/lib/due-dates.ts', DUE_DATES_LIB],
  ['src/lib/due-dates.test.ts', DUE_DATES_TEST],
  ['src/lib/money.ts', MONEY_LIB],
  ['src/lib/money.test.ts', MONEY_TEST],
];

/** Files each task must be able to find; the runner refuses to start without them. */
export const REQUIRED_BY_TASK = {
  'add-validation': ['src/components/InvoiceForm.tsx', 'src/lib/invoice.ts', 'src/lib/invoice.test.ts'],
  'find-the-flake': ['src/lib/due-dates.ts', 'src/lib/due-dates.test.ts', 'src/lib/money.test.ts'],
};

/** Writes the fixture into `project`. Returns the relative paths written. */
export function writeFixture(project) {
  const written = [];
  for (const [relative, contents] of FILES) {
    const absolute = join(project, relative);
    mkdirSync(join(absolute, '..'), { recursive: true });
    writeFileSync(absolute, contents, 'utf8');
    written.push(relative);
  }
  return written;
}

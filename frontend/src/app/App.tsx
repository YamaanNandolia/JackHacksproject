import { Suspense } from 'react';
import { RouterProvider } from 'react-router';
import { router } from './routes';
import { AppProvider } from './context/AppContext';

export default function App() {
  return (
    <AppProvider>
      <Suspense fallback={
        <div className="flex h-screen items-center justify-center bg-background text-foreground">
          <div className="h-10 w-10 animate-spin rounded-full border-2 border-muted-foreground border-t-foreground" />
        </div>
      }>
        <RouterProvider router={router} />
      </Suspense>
    </AppProvider>
  );
}
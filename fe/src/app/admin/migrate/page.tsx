'use client';

import { useState } from 'react';

export default function MigratePage() {
  const [migrateLoading, setMigrateLoading] = useState(false);
  const [seedLoading, setSeedLoading] = useState(false);
  const [migrateResult, setMigrateResult] = useState<any>(null);
  const [seedResult, setSeedResult] = useState<any>(null);

  const runMigration = async () => {
    setMigrateLoading(true);
    setMigrateResult(null);
    try {
      const response = await fetch('/api/admin/migrate', {
        method: 'POST',
      });
      const data = await response.json();
      setMigrateResult(data);
    } catch (error: any) {
      setMigrateResult({ success: false, error: error.message });
    } finally {
      setMigrateLoading(false);
    }
  };

  const runSeed = async () => {
    setSeedLoading(true);
    setSeedResult(null);
    try {
      const response = await fetch('/api/admin/seed', {
        method: 'POST',
      });
      const data = await response.json();
      setSeedResult(data);
    } catch (error: any) {
      setSeedResult({ success: false, error: error.message });
    } finally {
      setSeedLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-100 py-12 px-4">
      <div className="max-w-4xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Database Administration</h1>
        </div>
        
        <div className="bg-white rounded-lg shadow p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4">Run Database Migrations</h2>
          <p className="text-gray-600 mb-4">
            This will create all database tables and schema.
          </p>
          <button
            onClick={runMigration}
            disabled={migrateLoading}
            className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700 disabled:bg-gray-400"
          >
            {migrateLoading ? 'Running...' : 'Run Migrations'}
          </button>
          
          {migrateResult && (
            <div className={`mt-4 p-4 rounded ${migrateResult.success ? 'bg-green-50 border border-green-200' : 'bg-red-50 border border-red-200'}`}>
              <h3 className="font-semibold mb-2">
                {migrateResult.success ? '✅ Success' : '❌ Error'}
              </h3>
              <pre className="text-sm overflow-auto">
                {JSON.stringify(migrateResult, null, 2)}
              </pre>
            </div>
          )}
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">Seed Database</h2>
          <p className="text-gray-600 mb-4">
            This will populate the database with sample products and categories.
          </p>
          <button
            onClick={runSeed}
            disabled={seedLoading}
            className="bg-green-600 text-white px-6 py-2 rounded hover:bg-green-700 disabled:bg-gray-400"
          >
            {seedLoading ? 'Seeding...' : 'Seed Database'}
          </button>
          
          {seedResult && (
            <div className={`mt-4 p-4 rounded ${seedResult.success ? 'bg-green-50 border border-green-200' : 'bg-red-50 border border-red-200'}`}>
              <h3 className="font-semibold mb-2">
                {seedResult.success ? '✅ Success' : '❌ Error'}
              </h3>
              <pre className="text-sm overflow-auto">
                {JSON.stringify(seedResult, null, 2)}
              </pre>
            </div>
          )}
        </div>

        <div className="mt-8 bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <h3 className="font-semibold text-yellow-800 mb-2">⚠️ Security Warning</h3>
          <p className="text-yellow-700 text-sm">
            This page should be removed or protected in production. It provides direct access to database operations.
          </p>
        </div>
      </div>
    </div>
  );
}

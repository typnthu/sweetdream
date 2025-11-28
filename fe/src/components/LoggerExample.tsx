// Example component showing how to use the logger

'use client';

import { logger } from '@/lib/logger';
import { useEffect } from 'react';

export function LoggerExample() {
  // Log component mount
  useEffect(() => {
    logger.info('LoggerExample component mounted');
    
    return () => {
      logger.info('LoggerExample component unmounted');
    };
  }, []);

  const handleButtonClick = () => {
    logger.userAction('Example Button Clicked', {
      buttonName: 'Test Button',
      timestamp: new Date().toISOString()
    });
  };

  const handleApiCall = async () => {
    const startTime = Date.now();
    
    try {
      const response = await fetch('/api/proxy/products');
      const responseTime = Date.now() - startTime;
      const data = await response.json();
      
      logger.apiCall(
        'GET',
        '/api/proxy/products',
        response.status,
        responseTime,
        { productCount: data.products?.length || 0 }
      );
    } catch (error: any) {
      logger.error('API call failed', {
        endpoint: '/api/proxy/products',
        error: error.message,
        stack: error.stack
      });
    }
  };

  const handleError = () => {
    try {
      throw new Error('This is a test error');
    } catch (error: any) {
      logger.error('Test error thrown', {
        errorMessage: error.message,
        stack: error.stack
      });
    }
  };

  return (
    <div className="p-4 space-y-4">
      <h2 className="text-xl font-bold">Logger Example</h2>
      
      <div className="space-x-2">
        <button
          onClick={handleButtonClick}
          className="px-4 py-2 bg-blue-500 text-white rounded"
        >
          Log User Action
        </button>
        
        <button
          onClick={handleApiCall}
          className="px-4 py-2 bg-green-500 text-white rounded"
        >
          Log API Call
        </button>
        
        <button
          onClick={handleError}
          className="px-4 py-2 bg-red-500 text-white rounded"
        >
          Log Error
        </button>
      </div>
      
      <p className="text-sm text-gray-600">
        Check the browser console and backend logs to see the logged events.
      </p>
    </div>
  );
}

// App.js
import React, { useEffect, useState } from 'react';
import './App.css';
import { API_URL } from './config';

function App() {
  const [success, setSuccess] = useState();
  const [error,   setError]   = useState();

  useEffect(() => {
    fetch(API_URL)               // <-- must be defined at build time
      .then(r => r.json())
      .then(d => setSuccess(d.id))
      .catch(e => setError(e.message));
  }, []);

  if (!API_URL) return <div>❗️ Missing REACT_APP_API_URL!</div>;
  if (error)       return <div>Failed to fetch: {error}</div>;
  if (!success)    return <div>Fetching…</div>;
  return <div>{success}</div>;
}

export default App;

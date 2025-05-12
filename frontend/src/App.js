import React, { useEffect, useState } from 'react';
import './App.css';
import { API_URL } from './config';  // ✅ CRA will see this and inline it

function App() {
  const [successMessage, setSuccessMessage] = useState();
  const [failureMessage, setFailureMessage] = useState();

  useEffect(() => {
    const getId = async () => {
      try {
        // ✅ fallback logic handled in App.js only
        const apiUrl = API_URL || 'http://localhost:8080/';
        const resp = await fetch(apiUrl);
        const data = await resp.json();
        setSuccessMessage(data.id);
      } catch (e) {
        setFailureMessage(e.message);
      }
    };
    getId();
  }, []);

  return (
    <div className="App">
      {!failureMessage && !successMessage ? 'Fetching...' : null}
      {failureMessage ? failureMessage : null}
      {successMessage ? successMessage : null}
    </div>
  );
}

export default App;

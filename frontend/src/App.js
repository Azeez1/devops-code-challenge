import React, { useEffect, useState } from 'react';
import './App.css';

function App() {
  const [successMessage, setSuccessMessage] = useState();
  const [failureMessage, setFailureMessage] = useState();

  useEffect(() => {
    const getId = async () => {
      try {
        const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost:8080/';
        const resp = await fetch(apiUrl);
        const data = await resp.json();
        setSuccessMessage(data.id);
      } catch (e) {
        setFailureMessage(e.message);
      }
    };
    getId();
  }, []); // <-- Also added dependency array to prevent endless re-fetch

  return (
    <div className="App">
      {!failureMessage && !successMessage ? 'Fetching...' : null}
      {failureMessage ? failureMessage : null}
      {successMessage ? successMessage : null}
    </div>
  );
}

export default App;

import React, { useState, useEffect, useRef } from 'react';

export default function RobotDashboard() {
  const [connected, setConnected] = useState(false);
  const [telemetry, setTelemetry] = useState({
    battery: 0,
    weight: 0.0,
    obstacle: false,
    state: "DISCONNECTED"
  });

  const ws = useRef(null);

  useEffect(() => {
    // Dirección IP asignada al ESP32 principal
    ws.current = new WebSocket("ws://192.168.4.1:81/");

    ws.current.onopen = () => {
      setConnected(true);
    };

    ws.current.onclose = () => {
      setConnected(false);
      setTelemetry(prev => ({ ...prev, state: "DISCONNECTED" }));
    };

    ws.current.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        if (data.type === "telemetry") {
          setTelemetry({
            battery: data.battery,
            weight: data.weight,
            obstacle: data.obstacle,
            state: data.state
          });
        }
      } catch (err) {
        console.error("Error decodificando telemetría:", err);
      }
    };

    return () => {
      if (ws.current) ws.current.close();
    };
  }, []);

  // Enviar comando según el esquema JSON de la Sección 4.4 del PDF
  const sendMoveCommand = (vx, w) => {
    if (ws.current && connected) {
      const payload = {
        type: "movement",
        mode: "manual",
        vx: vx,
        vy: 0.0,
        w: w
      };
      ws.current.send(JSON.stringify(payload));
    }
  };

  const handleEmergencyStop = () => {
    sendMoveCommand(0.0, 0.0);
  };

  return (
    <div style={{ fontFamily: 'sans-serif', padding: 20, maxWidth: 450, margin: '0 auto' }}>
      <h2>Robot Transportador Inteligente</h2>
      
      {/* Panel de Conexión y Estado */}
      <div style={{ padding: 15, borderRadius: 8, background: connected ? '#e6fffa' : '#ffebee', marginBottom: 15 }}>
        <p><strong>Conexión:</strong> {connected ? "Conectado" : "Desconectado"}</p>
        <p><strong>Estado del Robot:</strong> {telemetry.state}</p>
        <p><strong>Batería:</strong> {telemetry.battery}%</p>
        <p><strong>Carga (HX711):</strong> {telemetry.weight.toFixed(2)} kg</p>
        {telemetry.obstacle && (
          <p style={{ color: 'red', fontWeight: 'bold' }}>⚠️ Obstáculo Detectado (ToF)</p>
        )}
      </div>

      {/* Controles de Movimiento Manual */}
      <h3>Control de Movimiento</h3>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
        <div></div>
        <button onClick={() => sendMoveCommand(0.3, 0.0)} style={btnStyle}>▲ Adelante</button>
        <div></div>

        <button onClick={() => sendMoveCommand(0.0, 1.5)} style={btnStyle}>◀ Giro Izq</button>
        <button onClick={() => sendMoveCommand(0.0, 0.0)} style={{ ...btnStyle, background: '#f44336', color: 'white' }}>■ Parar</button>
        <button onClick={() => sendMoveCommand(0.0, -1.5)} style={btnStyle}>▶ Giro Der</button>

        <div></div>
        <button onClick={() => sendMoveCommand(-0.3, 0.0)} style={btnStyle}>▼ Retroceso</button>
        <div></div>
      </div>

      {/* Botón Parada de Emergencia Prioritaria */}
      <div style={{ marginTop: 20 }}>
        <button 
          onClick={handleEmergencyStop} 
          style={{ width: '100%', padding: 15, background: '#d32f2f', color: 'white', border: 'none', borderRadius: 8, fontSize: 16, fontWeight: 'bold' }}>
          PARADA DE EMERGENCIA
        </button>
      </div>
    </div>
  );
}

const btnStyle = {
  padding: '12px',
  fontSize: '14px',
  cursor: 'pointer',
  borderRadius: '6px',
  border: '1px solid #ccc'
};


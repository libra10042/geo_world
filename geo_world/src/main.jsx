// main.jsx (확장자도 .jsx로 바꿔주세요)
import React from 'react'
import ReactDOM from 'react-dom/client'
import './style.css'
import { setupCounter } from './counter.js'
import { App } from './App.jsx'

// ReactDOM으로 App 컴포넌트 렌더링
const root = ReactDOM.createRoot(document.getElementById('app'))
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
)

// 기존 setupCounter 동작 유지
setupCounter(document.querySelector('#counter'))

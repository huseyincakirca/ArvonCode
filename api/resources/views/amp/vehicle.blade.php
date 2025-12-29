<!doctype html>
<html ⚡ lang="tr">
<head>
  <meta charset="utf-8">
  <title>ArvonCode | Araç Sahibi</title>
  <link rel="canonical" href="self">
  <meta name="viewport" content="width=device-width,minimum-scale=1,initial-scale=1">
  <style amp-boilerplate>
    body { -webkit-animation: -amp-start 8s steps(1,end) 0s 1 normal both; animation: -amp-start 8s steps(1,end) 0s 1 normal both; }
    @-webkit-keyframes -amp-start { from { visibility: hidden } to { visibility: visible } }
    @keyframes -amp-start { from { visibility: hidden } to { visibility: visible } }
  </style>
  <noscript>
    <style amp-boilerplate>
      body { -webkit-animation: none; animation: none; }
    </style>
  </noscript>

  <style amp-custom>
    body {
      background: #000;
      font-family: Arial, sans-serif;
      color: #fff;
      text-align: center;
      padding: 30px 20px;
    }

    .card {
      background: #0a0a0a;
      border-radius: 18px;
      padding: 25px;
      border: 1px solid #222;
      box-shadow: 0 0 25px rgba(0,255,255,0.08);
    }

    h1 {
      font-size: 28px;
      letter-spacing: 1px;
    }

    .info {
      margin-top: 15px;
      font-size: 18px;
      opacity: .85;
    }

    .btn {
      display: inline-block;
      background: #00eaff;
      color: #000;
      padding: 12px 22px;
      font-size: 18px;
      border-radius: 14px;
      margin-top: 25px;
      text-decoration: none;
      font-weight: bold;
    }

  </style>
</head>

<body>

  <div class="card">
    <h1>ArvonCode</h1>

    <div class="info">
      Bu araç sahibine mesaj göndermek için aşağıya tıklayın.
    </div>

    <a class="btn" href="/t/{{ $vehicle_id }}/contact">
      Araç Sahibine Ulaş
    </a>

  </div>

</body>
</html>

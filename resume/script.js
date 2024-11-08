function GetValueFromDB() {
  let counter = document.getElementById("count");
  let response;
  const API_URL = "https://functwcus0cloudresume1.azurewebsites.net";
  fetch(API_URL, {
    method: "POST",
    body: JSON.stringify({
      count: 1,
    }),
    headers: {
      "Content-type": "application/json; charset=UTF-8",
    },
  })
    .then((response) => response.json())
    .then((json) => console.log(json))
    .then((json) => response);

  counter = response.map("count");
}

GetValueFromDB();

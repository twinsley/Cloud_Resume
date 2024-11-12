function GetValueFromDB() {
  let counter = document.getElementById("count");
  let count = 0;
  let response;
  const API_URL =
    "https://functwcus0cloudresume1.azurewebsites.net/api/resumecounter";
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
    .then((data) => {
      console.log(data.TotalCount);
      count = data.TotalCount;
      counter.innerHTML = `Visitor Count: ${count}`;
    });
}

GetValueFromDB();

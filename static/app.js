(async function() {
  const response = await fetch("/articles.json");
  const articles = await response.json();

  console.log(articles);

  const list = document.getElementById("articles");

  articles.forEach(article => {
    const a = document.createElement("a");
    a.href = article.uri;
    a.innerText = article.title;

    const item = document.createElement("li");
    item.appendChild(a);

    list.appendChild(item);
  });
})();

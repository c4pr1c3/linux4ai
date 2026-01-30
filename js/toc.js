document.addEventListener('DOMContentLoaded', function() {
  const toc = document.getElementById('TOC');
  if (!toc) return;

  // Create toggle button
  const toggleBtn = document.createElement('button');
  toggleBtn.id = 'toc-toggle';
  toggleBtn.innerHTML = '目录';
  toggleBtn.title = '切换目录显示';
  
  // Add button to TOC
  toc.insertBefore(toggleBtn, toc.firstChild);

  // Initial state: check localStorage or default to expanded
  const isCollapsed = localStorage.getItem('toc-collapsed') === 'true';
  if (isCollapsed) {
    toc.classList.add('collapsed');
  }

  // Toggle function
  toggleBtn.addEventListener('click', function() {
    toc.classList.toggle('collapsed');
    localStorage.setItem('toc-collapsed', toc.classList.contains('collapsed'));
  });
});

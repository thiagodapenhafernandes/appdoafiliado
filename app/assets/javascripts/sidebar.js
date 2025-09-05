// Mobile sidebar toggle functionality
document.addEventListener('DOMContentLoaded', function() {
  const mobileMenuButton = document.getElementById('mobile-menu-button');
  const sidebar = document.querySelector('.md\\:w-64');
  
  if (mobileMenuButton && sidebar) {
    mobileMenuButton.addEventListener('click', function() {
      sidebar.classList.toggle('hidden');
    });
  }
});

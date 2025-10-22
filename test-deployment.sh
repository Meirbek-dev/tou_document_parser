#!/bin/bash

# Test script for TOU Document Parser deployment
# This script verifies that the application is working correctly

echo "=========================================="
echo "TOU Document Parser - Deployment Tests"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counter
PASSED=0
FAILED=0

# Function to print test results
test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC} - $2"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC} - $2"
        ((FAILED++))
    fi
}

echo ""
echo "Running tests..."
echo ""

# Test 1: Check if Docker is running
echo "Test 1: Docker daemon"
docker ps > /dev/null 2>&1
test_result $? "Docker daemon is running"

# Test 2: Check if container is running
echo "Test 2: Container status"
docker-compose ps | grep -q "Up"
test_result $? "Container is running"

# Test 3: Check if port 5040 is listening
echo "Test 3: Port availability"
netstat -tuln 2>/dev/null | grep -q ":5040" || ss -tuln 2>/dev/null | grep -q ":5040"
test_result $? "Port 5040 is listening"

# Test 4: Test backend health
echo "Test 4: Backend health check"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5040/ 2>/dev/null)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
    test_result 0 "Backend is responding (HTTP $HTTP_CODE)"
else
    test_result 1 "Backend is not responding"
fi

# Test 5: Check Nginx status (if installed)
echo "Test 5: Nginx status"
if command -v nginx > /dev/null 2>&1; then
    systemctl is-active --quiet nginx
    test_result $? "Nginx is running"
else
    echo -e "${YELLOW}⊘ SKIP${NC} - Nginx not installed"
fi

# Test 6: Check SSL certificate (if configured)
echo "Test 6: SSL certificate"
if [ -d "/etc/letsencrypt/live/ai-reception.tou.edu.kz" ]; then
    if [ -f "/etc/letsencrypt/live/ai-reception.tou.edu.kz/fullchain.pem" ]; then
        test_result 0 "SSL certificate exists"
    else
        test_result 1 "SSL certificate not found"
    fi
else
    echo -e "${YELLOW}⊘ SKIP${NC} - SSL not configured yet"
fi

# Test 7: Check uploads directory
echo "Test 7: Uploads directory"
if [ -d "uploads" ] && [ -w "uploads" ]; then
    test_result 0 "Uploads directory exists and is writable"
else
    test_result 1 "Uploads directory issue"
fi

# Test 8: Check container health
echo "Test 8: Container health"
HEALTH=$(docker inspect --format='{{.State.Health.Status}}' tou-document-parser 2>/dev/null)
if [ "$HEALTH" = "healthy" ] || [ -z "$HEALTH" ]; then
    test_result 0 "Container health OK"
else
    test_result 1 "Container health: $HEALTH"
fi

echo ""
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "Your application is ready!"
    echo "Access it at: https://ai-reception.tou.edu.kz"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo ""
    echo "Check the logs with: docker-compose logs"
    exit 1
fi

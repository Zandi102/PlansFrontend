<?php

//importing required script
require_once '../includes/DbOperation.php';

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'GET') {

    $compName = $_GET['compName'];
    $date = $_GET['date'];

    $db = new DbOperation();

    $response = $db->getAmountSponsored($compName, $date);
    
} else {
    $response['error'] = true;
    $response['message'] = 'Invalid request';
}

echo json_encode($response);

?>
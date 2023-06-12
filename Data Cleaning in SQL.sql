-- Cleaning Data in SQL Queries

-- Checking out the dataset
SELECT *
FROM dbo.Nashvillehousing

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format
ALTER TABLE Nashvillehousing
ADD SaleDateConverted Date;

UPDATE Nashvillehousing
SET SaleDateConverted = CONVERT(Date, Saledate)

SELECT SaleDateConverted
FROM dbo.Nashvillehousing

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address Data
-- We have null values in property column, We can use the ParcelID as reference to populate the null values in Property Address column 
SELECT *
FROM dbo.Nashvillehousing
WHERE PropertyAddress is null

-- This query will give us a new column for corrected PropertyAddress
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.nashvillehousing a
JOIN dbo.nashvillehousing b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null

-- We are now going to update the PropertyAddress in our dataset
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.nashvillehousing a
JOIN dbo.nashvillehousing b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null

-- We can check again if we already fixed the null values
SELECT PropertyAddress
FROM dbo.nashvillehousing
WHERE PropertyAddress is null

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual columns (Address, City, State) using SUBSTRING
-- We are going to seperate it by the comma delimiter
SELECT PropertyAddress
FROM dbo.nashvillehousing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1 ) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1 , LEN(PropertyAddress)) AS Address
FROM dbo.nashvillehousing

-- We need to add two columns for those seperate values and update our dataset

-- 1st PropertySplitAddress
ALTER TABLE Nashvillehousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE Nashvillehousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1 )

-- 2nd PropertySplitCity
ALTER TABLE Nashvillehousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE Nashvillehousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1 , LEN(PropertyAddress))

-- Let's check if its added into our dataset
SELECT PropertySplitAddress, PropertySplitCity
FROM Nashvillehousing

-- We can also PARSENAME to quickly split the OwnerAddress column, this can also be done with the PropertyAddress on our above query

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM Nashvillehousing

-- We can now add and update three new columns for those new values in our dataset

-- 1st OwnerSplitAddress #Note : run the query for alter table first
ALTER TABLE Nashvillehousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE Nashvillehousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

-- 2nd OwnerSplitCity #Note : run the query for alter table first
ALTER TABLE Nashvillehousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE Nashvillehousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

-- 3rd OwnerSplitState #Note : run the query for alter table first
ALTER TABLE Nashvillehousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE Nashvillehousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Let's check our updated dataset
SELECT OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM Nashvillehousing

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

-- First we going to look at the data
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2

-- We are now going to run a query with a CASE WHEN statement to change Y to Yes and N to No and UPDATE our dataset
SELECT SoldAsVacant
, CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM Nashvillehousing

UPDATE Nashvillehousing
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

-- Let's check if it's changed
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Removing Duplicates :: I don't usually delete data. It is not a standard practice to delete data that's in our database. 
-- We are just doing this to demonstrate that we can remove unusable data.

-- USING CTE
WITH RowNumCTE as (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM Nashvillehousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- We found 104 duplicate rows in our dataset. Let's go and remove those

WITH RowNumCTE as (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM Nashvillehousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

-- Let's check our CTE again if we did actually remove those duplicates

WITH RowNumCTE as (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM Nashvillehousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Now that we removed duplicate data, we can proceed with removing some unused columns :: #NOTE : We don't do this in our actual main or raw Dataset

SELECT *
FROM Nashvillehousing

ALTER TABLE Nashvillehousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
